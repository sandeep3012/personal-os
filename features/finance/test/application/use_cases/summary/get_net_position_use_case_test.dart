import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_net_position_use_case.dart';
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
) {
  final date = DateTime(2024, 6, 15);
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
  late GetNetPositionUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    useCase = GetNetPositionUseCase(
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
    );
  });

  group('GetNetPositionUseCase', () {
    test('returns zero when no transactions exist', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(GetNetPositionInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.amount, Decimal.zero);
    });

    test('returns positive net when income exceeds expenses', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('t1', accId, TransactionType.income, '5000'),
        _txn('t2', accId, TransactionType.expense, '2000'),
      ]);

      final result = await useCase.execute(GetNetPositionInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('3000'));
    });

    test('returns negative net when expenses exceed income', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _txn('t1', accId, TransactionType.income, '1000'),
        _txn('t2', accId, TransactionType.expense, '3000'),
      ]);

      final result = await useCase.execute(GetNetPositionInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('-2000'));
    });

    test('transfer legs cancel out in net position', () async {
      // A transfer produces one expense + one income of equal amounts.
      // Net contribution of a transfer = 0.
      const accA = AccountId('acc-a');
      const accB = AccountId('acc-b');
      accountRepo.seed([_account('acc-a'), _account('acc-b')]);
      txnRepo.seed([
        _txn('real-income', accA, TransactionType.income, '5000'),
        _txn('debit-leg', accA, TransactionType.expense, '1000'),
        _txn('credit-leg', accB, TransactionType.income, '1000'),
      ]);

      final result = await useCase.execute(GetNetPositionInput(
        workspaceId: _ws,
        period: _period,
        currency: _inr,
      ));

      // 5000 (income) + 1000 (credit transfer) - 1000 (debit transfer) = 5000
      expect(result.valueOrNull!.amount, Decimal.parse('5000'));
    });
  });
}
