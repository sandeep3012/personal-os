import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/transaction/create_transfer_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/specifications/transfer_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/fake_transaction_repository.dart';

// ── Stubs ─────────────────────────────────────────────────────────────────────

final class _SequentialId implements IdGenerator {
  int _i = 0;
  @override
  String generate() => 'txn-${++_i}';
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Money _money(String amount, {String currency = 'INR'}) =>
    Money(amount: Decimal.parse(amount), currency: CurrencyCode(currency));

Account _account(String id, {bool isActive = true, String currency = 'INR'}) {
  final now = DateTime(2024, 1, 1);
  final cc = CurrencyCode(currency);
  return Account(
    id: AccountId(id),
    workspaceId: 'ws-1',
    name: 'Account $id',
    type: AccountType.savings,
    currency: cc,
    initialBalance: Money(amount: Decimal.zero, currency: cc),
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

final _date = TransactionDate(DateTime(2024, 7, 1));
const _from = AccountId('acc-from');
const _to = AccountId('acc-to');
const _ws = 'ws-1';

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository repo;
  late CreateTransferUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    repo = FakeTransactionRepository();
    useCase = CreateTransferUseCase(
      transactionRepository: repo,
      transferService: TransferService(idGenerator: _SequentialId()),
      specification:
          TransferCanBeCreatedSpecification(accountRepository: accountRepo),
    );
  });

  group('CreateTransferUseCase', () {
    test('creates debit and credit legs and persists them', () async {
      accountRepo.seed([_account('acc-from'), _account('acc-to')]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('1000'),
        date: _date,
      ));

      expect(result.isSuccess, isTrue);
      expect(repo.store, hasLength(2));
    });

    test('debit is expense on fromAccount', () async {
      accountRepo.seed([_account('acc-from'), _account('acc-to')]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('500'),
        date: _date,
      ));

      final output = result.valueOrNull!;
      expect(output.debit.type, TransactionType.expense);
      expect(output.debit.accountId, _from);
    });

    test('credit is income on toAccount', () async {
      accountRepo.seed([_account('acc-from'), _account('acc-to')]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('500'),
        date: _date,
      ));

      final output = result.valueOrNull!;
      expect(output.credit.type, TransactionType.income);
      expect(output.credit.accountId, _to);
    });

    test('both legs reference each other via transferCounterpartId', () async {
      accountRepo.seed([_account('acc-from'), _account('acc-to')]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('200'),
        date: _date,
      ));

      final output = result.valueOrNull!;
      expect(output.debit.transferCounterpartId, output.credit.id);
      expect(output.credit.transferCounterpartId, output.debit.id);
    });

    test('fails when fromAccount equals toAccount (Invariant 4)', () async {
      accountRepo.seed([_account('acc-from')]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _from,
        amount: _money('100'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });

    test('both legs share the same amount', () async {
      accountRepo.seed([_account('acc-from'), _account('acc-to')]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('750'),
        date: _date,
      ));

      final output = result.valueOrNull!;
      expect(output.debit.amount.amount, output.credit.amount.amount);
      expect(output.debit.amount.amount, Decimal.parse('750'));
    });

    // ── Specification integration ─────────────────────────────────────────────

    test('fails when source account does not exist and nothing is persisted',
        () async {
      accountRepo.seed([_account('acc-to')]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('100'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(repo.store, isEmpty);
    });

    test('fails when destination account does not exist', () async {
      accountRepo.seed([_account('acc-from')]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('100'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(repo.store, isEmpty);
    });

    test('fails when source account is inactive', () async {
      accountRepo.seed([
        _account('acc-from', isActive: false),
        _account('acc-to'),
      ]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('100'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(
        (result.exceptionOrNull as FinanceException).message,
        contains('inactive'),
      );
      expect(repo.store, isEmpty);
    });

    test('fails when destination account is inactive', () async {
      accountRepo.seed([
        _account('acc-from'),
        _account('acc-to', isActive: false),
      ]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('100'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(repo.store, isEmpty);
    });

    test('fails on currency mismatch between accounts', () async {
      accountRepo.seed([
        _account('acc-from', currency: 'INR'),
        _account('acc-to', currency: 'USD'),
      ]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('100', currency: 'INR'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(
        (result.exceptionOrNull as FinanceException).message,
        allOf(contains('INR'), contains('USD')),
      );
      expect(repo.store, isEmpty);
    });

    test('validation succeeds and both legs are persisted normally', () async {
      accountRepo.seed([
        _account('acc-from', currency: 'USD'),
        _account('acc-to', currency: 'USD'),
      ]);

      final result = await useCase.execute(CreateTransferInput(
        workspaceId: _ws,
        fromAccountId: _from,
        toAccountId: _to,
        amount: _money('400', currency: 'USD'),
        date: _date,
      ));

      expect(result.isSuccess, isTrue);
      expect(repo.store, hasLength(2));
    });
  });
}
