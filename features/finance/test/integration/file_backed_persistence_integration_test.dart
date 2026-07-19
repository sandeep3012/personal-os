import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/data/dao/account_dao.dart';
import 'package:feature_finance/src/data/dao/transaction_dao.dart';
import 'package:feature_finance/src/data/database/file_backed_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/file_backed_finance_transaction_runner.dart';
import 'package:feature_finance/src/data/mappers/account_mapper.dart';
import 'package:feature_finance/src/data/mappers/transaction_mapper.dart';
import 'package:feature_finance/src/data/repositories/account_repository.dart';
import 'package:feature_finance/src/data/repositories/transaction_repository.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

const _ws = 'ws-1';
final _inr = CurrencyCode('INR');

/// Verifies Finance data written through
/// [FileBackedFinanceDatabaseExecutor]/[FileBackedFinanceTransactionRunner]
/// genuinely survives being "closed and reopened" — i.e. a fresh
/// [FileBackedFinanceDatabaseExecutor.open] call against the same file,
/// standing in for the app being killed and relaunched. This is the
/// persistence guarantee [InMemoryFinanceDatabaseExecutor] alone cannot
/// make (its state lives only for the process lifetime).
void main() {
  late Directory tempDir;
  late File storageFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('finance_file_persistence_');
    storageFile = File('${tempDir.path}/finance_data.json');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ({
    AccountRepository accounts,
    TransactionRepository transactions,
  }) buildRepositories(FileBackedFinanceDatabaseExecutor executor) {
    final runner = FileBackedFinanceTransactionRunner(executor);
    return (
      accounts: AccountRepository(
        accountDao: AccountDao(executor),
        accountMapper: const AccountMapper(),
      ),
      transactions: TransactionRepository(
        transactionDao: TransactionDao(executor),
        transactionMapper: const TransactionMapper(),
        transactionRunner: runner,
      ),
    );
  }

  test('an Account persists across a simulated app restart', () async {
    final firstExecutor = await FileBackedFinanceDatabaseExecutor.open(storageFile);
    final firstRepos = buildRepositories(firstExecutor);

    final account = _account('acc-1', name: 'Checking');
    await firstRepos.accounts.save(account);

    // Simulate "kill the app and relaunch": a brand-new executor opened
    // against the same file, with no shared in-memory state.
    final secondExecutor = await FileBackedFinanceDatabaseExecutor.open(storageFile);
    final secondRepos = buildRepositories(secondExecutor);

    final result = await secondRepos.accounts.findById(account.id, workspaceId: _ws);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.name, 'Checking');
  });

  test('a Transaction persists across a simulated app restart', () async {
    final firstExecutor = await FileBackedFinanceDatabaseExecutor.open(storageFile);
    final firstRepos = buildRepositories(firstExecutor);
    final account = _account('acc-1');
    await firstRepos.accounts.save(account);

    final txn = _expense('txn-1', account.id, '250');
    await firstRepos.transactions.save(txn);

    final secondExecutor = await FileBackedFinanceDatabaseExecutor.open(storageFile);
    final secondRepos = buildRepositories(secondExecutor);

    final result =
        await secondRepos.transactions.findById(txn.id, workspaceId: _ws);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.amount.amount, Decimal.parse('250'));
  });

  test('a Transfer (both legs) persists across a simulated app restart',
      () async {
    final firstExecutor = await FileBackedFinanceDatabaseExecutor.open(storageFile);
    final firstRepos = buildRepositories(firstExecutor);
    final from = _account('acc-from');
    final to = _account('acc-to');
    await firstRepos.accounts.save(from);
    await firstRepos.accounts.save(to);

    final transferService =
        TransferService(idGenerator: _FixedIdGenerator('debit-1', 'credit-1'));
    final (debit, credit) = transferService.createTransferPair(
      workspaceId: _ws,
      fromAccountId: from.id,
      toAccountId: to.id,
      amount: Money(amount: Decimal.parse('500'), currency: _inr),
      date: TransactionDate(DateTime(2024, 1, 1)),
    );
    await firstRepos.transactions.saveTransferPair(debit, credit);

    final secondExecutor = await FileBackedFinanceDatabaseExecutor.open(storageFile);
    final secondRepos = buildRepositories(secondExecutor);

    final debitResult =
        await secondRepos.transactions.findById(debit.id, workspaceId: _ws);
    final creditResult =
        await secondRepos.transactions.findById(credit.id, workspaceId: _ws);
    expect(debitResult.valueOrNull, isNotNull);
    expect(creditResult.valueOrNull, isNotNull);
    expect(
      debitResult.valueOrNull!.transferCounterpartId,
      credit.id,
    );
  });

  test('a rolled-back transfer leaves no partial data on disk after restart',
      () async {
    final firstExecutor = await FileBackedFinanceDatabaseExecutor.open(storageFile);
    final firstRepos = buildRepositories(firstExecutor);
    final from = _account('acc-from');
    await firstRepos.accounts.save(from);

    final debit = _expense('debit-1', from.id, '100');
    final credit = _expense('credit-1', from.id, '100');

    // Force the second insert of the pair to throw, so the transaction
    // rolls back — proving the rollback (not just the commit path) is
    // correctly reflected on disk.
    firstExecutor.engine
      ..insertError = Exception('forced failure')
      ..throwOnInsertCallIndex = 1;

    final saveResult = await firstRepos.transactions.saveTransferPair(debit, credit);
    expect(saveResult.isFailure, isTrue);

    final secondExecutor = await FileBackedFinanceDatabaseExecutor.open(storageFile);
    final secondRepos = buildRepositories(secondExecutor);
    final findResult =
        await secondRepos.transactions.findById(debit.id, workspaceId: _ws);

    // Either both legs are absent (rollback succeeded) — never a partial
    // single-leg write surviving to disk.
    expect(findResult.valueOrNull, isNull);
  });
}

final class _FixedIdGenerator implements IdGenerator {
  _FixedIdGenerator(this._first, this._second);
  final String _first;
  final String _second;
  var _calls = 0;
  @override
  String generate() => _calls++ == 0 ? _first : _second;
}

Account _account(String id, {String name = 'Account'}) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: name,
    type: AccountType.savings,
    currency: _inr,
    initialBalance: Money(amount: Decimal.parse('1000'), currency: _inr),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _expense(String id, AccountId accountId, String amount) {
  final now = DateTime(2024, 1, 1);
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: accountId,
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse(amount), currency: _inr),
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}
