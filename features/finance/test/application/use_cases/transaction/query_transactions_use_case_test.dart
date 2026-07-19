import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/transaction/query_transactions_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/fake_transaction_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');
const _ws = 'ws-1';
const _accId = AccountId('acc-1');

Account _account(String id) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: 'Account $id',
    type: AccountType.savings,
    currency: _inr,
    initialBalance: Money(amount: Decimal.zero, currency: _inr),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _txn(
  String id, {
  TransactionType type = TransactionType.expense,
  CategoryId? categoryId,
  Payee? payee,
}) {
  final now = DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: _accId,
    type: type,
    amount: Money(amount: Decimal.parse('100'), currency: _inr),
    categoryId: categoryId,
    payee: payee,
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late QueryTransactionsUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    useCase = QueryTransactionsUseCase(
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
    );
  });

  group('QueryTransactionsUseCase', () {
    test('returns all transactions when no filters applied', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_txn('t1'), _txn('t2'), _txn('t3')]);

      final result = await useCase.execute(const TransactionQuery(
        workspaceId: _ws,
        accountId: _accId,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.totalCount, 3);
      expect(result.valueOrNull!.items, hasLength(3));
    });

    test('filters by transaction type', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('exp', type: TransactionType.expense),
        _txn('inc', type: TransactionType.income),
      ]);

      final result = await useCase.execute(const TransactionQuery(
        workspaceId: _ws,
        accountId: _accId,
        type: TransactionType.income,
      ));

      expect(result.valueOrNull!.items, hasLength(1));
      expect(result.valueOrNull!.items.first.id.value, 'inc');
    });

    test('filters by categoryId', () async {
      accountRepo.seed([_account('acc-1')]);
      const cat = CategoryId('cat-food');
      txnRepo.seed([
        _txn('t1', categoryId: cat),
        _txn('t2'),
      ]);

      final result = await useCase.execute(const TransactionQuery(
        workspaceId: _ws,
        accountId: _accId,
        categoryId: cat,
      ));

      expect(result.valueOrNull!.items, hasLength(1));
      expect(result.valueOrNull!.items.first.id.value, 't1');
    });

    test('filters by payeeNameContains (case-insensitive)', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('t1', payee: Payee('Amazon')),
        _txn('t2', payee: Payee('Flipkart')),
      ]);

      final result = await useCase.execute(const TransactionQuery(
        workspaceId: _ws,
        accountId: _accId,
        payeeNameContains: 'amaz',
      ));

      expect(result.valueOrNull!.items, hasLength(1));
      expect(result.valueOrNull!.items.first.payee?.value, 'Amazon');
    });

    test('paginates correctly', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed(List.generate(
          15, (i) => _txn('t${i + 1}')));

      final result = await useCase.execute(const TransactionQuery(
        workspaceId: _ws,
        accountId: _accId,
        pageIndex: 1,
        pageSize: 5,
      ));

      expect(result.valueOrNull!.items, hasLength(5));
      expect(result.valueOrNull!.totalCount, 15);
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });

    test('hasNextPage is false on the last page', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed(List.generate(3, (i) => _txn('t${i + 1}')));

      final result = await useCase.execute(const TransactionQuery(
        workspaceId: _ws,
        accountId: _accId,
        pageIndex: 0,
        pageSize: 5,
      ));

      expect(result.valueOrNull!.hasNextPage, isFalse);
    });

    test('returns empty page when no transactions match filters', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_txn('t1', type: TransactionType.expense)]);

      final result = await useCase.execute(const TransactionQuery(
        workspaceId: _ws,
        accountId: _accId,
        type: TransactionType.income,
      ));

      expect(result.valueOrNull!.items, isEmpty);
      expect(result.valueOrNull!.totalCount, 0);
      expect(result.valueOrNull!.hasNextPage, isFalse);
    });
  });
}
