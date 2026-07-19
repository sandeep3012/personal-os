import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_balance_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/fake_transaction_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');

Money _money(String amount) =>
    Money(amount: Decimal.parse(amount), currency: _inr);

Account _account(String id, {String initialBalance = '0'}) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: 'ws-1',
    name: 'Account $id',
    type: AccountType.savings,
    currency: _inr,
    initialBalance: _money(initialBalance),
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
  final now = DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: 'ws-1',
    accountId: accountId,
    type: type,
    amount: _money(amount),
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late GetAccountBalanceUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    useCase = GetAccountBalanceUseCase(
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
      balanceCalculationService: const BalanceCalculationService(),
    );
  });

  group('GetAccountBalanceUseCase', () {
    test('returns initial balance when no transactions', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1', initialBalance: '10000')]);

      final result = await useCase.execute(const GetAccountBalanceInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.amount, Decimal.parse('10000'));
    });

    test('adds income to initial balance', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1', initialBalance: '1000')]);
      txnRepo.seed([_txn('t1', accId, TransactionType.income, '500')]);

      final result = await useCase.execute(const GetAccountBalanceInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('1500'));
    });

    test('subtracts expense from initial balance', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1', initialBalance: '2000')]);
      txnRepo.seed([_txn('t1', accId, TransactionType.expense, '300')]);

      final result = await useCase.execute(const GetAccountBalanceInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('1700'));
    });

    test('calculates balance with multiple transactions', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1', initialBalance: '5000')]);
      txnRepo.seed([
        _txn('t1', accId, TransactionType.income, '2000'),
        _txn('t2', accId, TransactionType.expense, '800'),
        _txn('t3', accId, TransactionType.income, '300'),
      ]);

      final result = await useCase.execute(const GetAccountBalanceInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.valueOrNull!.amount, Decimal.parse('6500'));
    });

    test('fails with FinanceException when account not found', () async {
      final result = await useCase.execute(const GetAccountBalanceInput(
        accountId: AccountId('missing'),
        workspaceId: 'ws-1',
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });
  });
}
