import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_expenses_use_case.dart';
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
final _period = FinancePeriod(year: 2024, month: 6);

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

Transaction _txn(
  String id,
  AccountId accountId,
  TransactionType type,
  String amount,
  DateTime date,
) {
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: accountId,
    type: type,
    amount: _money(amount),
    date: TransactionDate(date),
    createdAt: date,
    updatedAt: date,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late GetTotalExpensesUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    useCase = GetTotalExpensesUseCase(
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
    );
  });

  group('GetTotalExpensesUseCase', () {
    test('returns zero when no transactions exist', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(GetTotalExpensesInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.amount, Decimal.zero);
    });

    test('sums expenses for the period', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('t1', accId, TransactionType.expense, '500', DateTime(2024, 6, 5)),
        _txn('t2', accId, TransactionType.expense, '300', DateTime(2024, 6, 20)),
      ]);

      final result = await useCase.execute(GetTotalExpensesInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('800'));
    });

    test('ignores income transactions', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('t1', accId, TransactionType.income, '1000', DateTime(2024, 6, 5)),
        _txn('t2', accId, TransactionType.expense, '200', DateTime(2024, 6, 10)),
      ]);

      final result = await useCase.execute(GetTotalExpensesInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('200'));
    });

    test('ignores transactions outside the period', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('in-period', accId, TransactionType.expense, '400', DateTime(2024, 6, 15)),
        _txn('out-period', accId, TransactionType.expense, '999', DateTime(2024, 7, 1)),
      ]);

      final result = await useCase.execute(GetTotalExpensesInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('400'));
    });

    test('aggregates across multiple accounts', () async {
      const accA = AccountId('acc-a');
      const accB = AccountId('acc-b');
      accountRepo.seed([_account('acc-a'), _account('acc-b')]);
      txnRepo.seed([
        _txn('t1', accA, TransactionType.expense, '100', DateTime(2024, 6, 1)),
        _txn('t2', accB, TransactionType.expense, '200', DateTime(2024, 6, 1)),
      ]);

      final result = await useCase.execute(GetTotalExpensesInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('300'));
    });
  });
}
