import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_category_summary_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/services/category_summary_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/fake_transaction_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');
const _ws = 'ws-1';
const _catFood = CategoryId('cat-food');
const _catTravel = CategoryId('cat-travel');

Money _money(String amount) =>
    Money(amount: Decimal.parse(amount), currency: _inr);

Account _account(String id) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: 'Account $id',
    type: AccountType.savings,
    currency: _inr,
    initialBalance: _money('0'),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _expense(
  String id,
  AccountId accountId, {
  required String amount,
  CategoryId? categoryId,
}) {
  final date = DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: accountId,
    type: TransactionType.expense,
    amount: _money(amount),
    categoryId: categoryId,
    date: TransactionDate(date),
    createdAt: date,
    updatedAt: date,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late GetCategorySummaryUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    useCase = GetCategorySummaryUseCase(
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
      categorySummaryService: const CategorySummaryService(),
    );
  });

  group('GetCategorySummaryUseCase', () {
    test('returns empty map when no transactions exist', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(GetCategorySummaryInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('sums expenses by category', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _expense('t1', accId, amount: '200', categoryId: _catFood),
        _expense('t2', accId, amount: '150', categoryId: _catFood),
        _expense('t3', accId, amount: '800', categoryId: _catTravel),
      ]);

      final result = await useCase.execute(GetCategorySummaryInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      ));

      final summary = result.valueOrNull!;
      expect(summary[_catFood]?.amount, Decimal.parse('350'));
      expect(summary[_catTravel]?.amount, Decimal.parse('800'));
    });

    test('excludes uncategorised expenses', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _expense('t1', accId, amount: '100', categoryId: _catFood),
        _expense('t2', accId, amount: '50'),
      ]);

      final result = await useCase.execute(GetCategorySummaryInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      ));

      expect(result.valueOrNull!, hasLength(1));
      expect(result.valueOrNull![_catFood]?.amount, Decimal.parse('100'));
    });

    test('aggregates categories across multiple accounts', () async {
      const accA = AccountId('acc-a');
      const accB = AccountId('acc-b');
      accountRepo.seed([_account('acc-a'), _account('acc-b')]);
      txnRepo.seed([
        _expense('t1', accA, amount: '300', categoryId: _catFood),
        _expense('t2', accB, amount: '200', categoryId: _catFood),
      ]);

      final result = await useCase.execute(GetCategorySummaryInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      ));

      expect(result.valueOrNull![_catFood]?.amount, Decimal.parse('500'));
    });

    test('period filtering used in FinancePeriod — wrong month excluded',
        () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      final julyDate = DateTime(2024, 7, 1);
      txnRepo.seed([
        Transaction(
          id: const TransactionId('t-july'),
          workspaceId: _ws,
          accountId: accId,
          type: TransactionType.expense,
          amount: _money('500'),
          categoryId: _catFood,
          date: TransactionDate(julyDate),
          createdAt: julyDate,
          updatedAt: julyDate,
        ),
      ]);

      final result = await useCase.execute(GetCategorySummaryInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      ));

      expect(result.valueOrNull, isEmpty);
    });
  });
}
