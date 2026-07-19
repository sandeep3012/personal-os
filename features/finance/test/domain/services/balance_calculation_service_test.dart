import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');

Money _money(String amount) =>
    Money(amount: Decimal.parse(amount), currency: _inr);

Transaction _txn(
  String id,
  TransactionType type,
  String amount,
) =>
    Transaction(
      id: TransactionId(id),
      workspaceId: 'ws-1',
      accountId: const AccountId('acc-1'),
      type: type,
      amount: _money(amount),
      date: TransactionDate(DateTime(2024, 6, 1)),
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

// Transfer legs require a counterpartId; helper sets a placeholder.
Transaction _transferTxn(String id, String amount) => Transaction(
      id: TransactionId(id),
      workspaceId: 'ws-1',
      accountId: const AccountId('acc-1'),
      type: TransactionType.transfer,
      amount: _money(amount),
      date: TransactionDate(DateTime(2024, 6, 1)),
      transferCounterpartId: const TransactionId('other-leg'),
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const service = BalanceCalculationService();

  group('BalanceCalculationService', () {
    test('empty transaction list returns the initial balance unchanged',
        () {
      final result = service.calculateBalance(_money('1000'), []);
      expect(result.amount, Decimal.parse('1000'));
    });

    test('income transaction adds to the initial balance', () {
      final result = service.calculateBalance(
        _money('500'),
        [_txn('t1', TransactionType.income, '200')],
      );
      expect(result.amount, Decimal.parse('700'));
    });

    test('expense transaction subtracts from the initial balance', () {
      final result = service.calculateBalance(
        _money('500'),
        [_txn('t1', TransactionType.expense, '150')],
      );
      expect(result.amount, Decimal.parse('350'));
    });

    test('multiple income and expense transactions accumulate correctly', () {
      final result = service.calculateBalance(
        _money('1000'),
        [
          _txn('t1', TransactionType.income, '500'),
          _txn('t2', TransactionType.expense, '200'),
          _txn('t3', TransactionType.expense, '300'),
          _txn('t4', TransactionType.income, '100'),
        ],
      );
      // 1000 + 500 - 200 - 300 + 100 = 1100
      expect(result.amount, Decimal.parse('1100'));
    });

    test('result currency matches the initial balance currency', () {
      final result = service.calculateBalance(
        _money('0'),
        [_txn('t1', TransactionType.income, '50')],
      );
      expect(result.currency, _inr);
    });

    test('balance can go negative when expenses exceed initial balance', () {
      final result = service.calculateBalance(
        _money('100'),
        [_txn('t1', TransactionType.expense, '300')],
      );
      expect(result.amount, Decimal.parse('-200'));
    });

    test('zero initial balance with only income equals the income amount', () {
      final result = service.calculateBalance(
        _money('0'),
        [_txn('t1', TransactionType.income, '250')],
      );
      expect(result.amount, Decimal.parse('250'));
    });

    test('income and expense that cancel out return the initial balance', () {
      final result = service.calculateBalance(
        _money('500'),
        [
          _txn('t1', TransactionType.income, '200'),
          _txn('t2', TransactionType.expense, '200'),
        ],
      );
      expect(result.amount, Decimal.parse('500'));
    });

    test('passing a type=transfer transaction throws FinanceException', () {
      expect(
        () => service.calculateBalance(_money('500'), [_transferTxn('t1', '100')]),
        throwsA(isA<FinanceException>()),
      );
    });

    test('Decimal precision is preserved (no floating-point error)', () {
      final result = service.calculateBalance(
        _money('0.1'),
        [_txn('t1', TransactionType.income, '0.2')],
      );
      expect(result.amount, Decimal.parse('0.3'));
    });
  });
}
