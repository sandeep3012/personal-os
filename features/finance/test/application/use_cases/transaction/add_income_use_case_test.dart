import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_income_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/specifications/transaction_can_be_created_specification.dart';
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

// ── Stub ──────────────────────────────────────────────────────────────────────

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

final _date = TransactionDate(DateTime(2024, 3, 10));
const _accId = AccountId('acc-1');
const _ws = 'ws-1';

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository repo;
  late AddIncomeUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    repo = FakeTransactionRepository();
    useCase = AddIncomeUseCase(
      transactionRepository: repo,
      idGenerator: _SequentialId(),
      specification:
          TransactionCanBeCreatedSpecification(accountRepository: accountRepo),
    );
  });

  group('AddIncomeUseCase', () {
    test('creates and persists an income transaction', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(AddIncomeInput(
        workspaceId: _ws,
        accountId: _accId,
        amount: _money('5000'),
        date: _date,
      ));

      expect(result.isSuccess, isTrue);
      final txn = result.valueOrNull!;
      expect(txn.type, TransactionType.income);
      expect(txn.amount.amount, Decimal.parse('5000'));
      expect(repo.store, contains(txn));
    });

    test('assigns generated id', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(AddIncomeInput(
        workspaceId: _ws,
        accountId: _accId,
        amount: _money('1000'),
        date: _date,
      ));

      expect(result.valueOrNull!.id.value, 'txn-1');
    });

    test('fails when amount is zero (entity invariant)', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(AddIncomeInput(
        workspaceId: _ws,
        accountId: _accId,
        amount: _money('0'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });

    test('defaults to empty attachmentIds', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(AddIncomeInput(
        workspaceId: _ws,
        accountId: _accId,
        amount: _money('100'),
        date: _date,
      ));

      expect(result.valueOrNull!.attachmentIds, isEmpty);
    });

    // ── Specification integration ─────────────────────────────────────────────

    test('fails when account does not exist', () async {
      final result = await useCase.execute(AddIncomeInput(
        workspaceId: _ws,
        accountId: _accId,
        amount: _money('100'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(repo.store, isEmpty);
    });

    test('fails when account is inactive and repository save never runs',
        () async {
      accountRepo.seed([_account('acc-1', isActive: false)]);

      final result = await useCase.execute(AddIncomeInput(
        workspaceId: _ws,
        accountId: _accId,
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

    test('fails on currency mismatch between transaction and account',
        () async {
      accountRepo.seed([_account('acc-1', currency: 'INR')]);

      final result = await useCase.execute(AddIncomeInput(
        workspaceId: _ws,
        accountId: _accId,
        amount: _money('100', currency: 'EUR'),
        date: _date,
      ));

      expect(result.isFailure, isTrue);
      expect(
        (result.exceptionOrNull as FinanceException).message,
        allOf(contains('EUR'), contains('INR')),
      );
      expect(repo.store, isEmpty);
    });

    test('validation succeeds and persistence continues normally', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(AddIncomeInput(
        workspaceId: _ws,
        accountId: _accId,
        amount: _money('2500'),
        date: _date,
      ));

      expect(result.isSuccess, isTrue);
      expect(repo.store, hasLength(1));
    });
  });
}
