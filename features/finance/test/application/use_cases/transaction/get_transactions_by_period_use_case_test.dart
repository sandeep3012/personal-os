import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/transaction/get_transactions_by_period_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
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

Transaction _txn(String id, AccountId accountId, DateTime date) {
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: accountId,
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse('100'), currency: _inr),
    date: TransactionDate(date),
    createdAt: date,
    updatedAt: date,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late GetTransactionsByPeriodUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    useCase = GetTransactionsByPeriodUseCase(
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
    );
  });

  group('GetTransactionsByPeriodUseCase', () {
    test('returns all transactions in the given month across accounts',
        () async {
      const accA = AccountId('acc-a');
      const accB = AccountId('acc-b');
      accountRepo.seed([_account('acc-a'), _account('acc-b')]);
      txnRepo.seed([
        _txn('t1', accA, DateTime(2024, 6, 5)),
        _txn('t2', accB, DateTime(2024, 6, 20)),
        _txn('t3', accA, DateTime(2024, 7, 1)),  // outside period
      ]);

      final result = await useCase.execute(GetTransactionsByPeriodInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(2));
      expect(result.valueOrNull!.map((t) => t.id.value),
          containsAll(['t1', 't2']));
    });

    test('returns empty list when no accounts exist', () async {
      final result = await useCase.execute(GetTransactionsByPeriodInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('handles December month boundary correctly', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('dec-31', accId, DateTime(2024, 12, 31)),
        _txn('jan-1', accId, DateTime(2025, 1, 1)),
      ]);

      final result = await useCase.execute(GetTransactionsByPeriodInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 12),
      ));

      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id.value, 'dec-31');
    });

    test('returns empty list when no transactions in the period', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('t1', const AccountId('acc-1'), DateTime(2024, 5, 15)),
      ]);

      final result = await useCase.execute(GetTransactionsByPeriodInput(
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });
}
