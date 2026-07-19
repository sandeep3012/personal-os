import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

final _inr = CurrencyCode('INR');

Transaction _makeExpense({
  String id = 'txn-1',
  String amount = '100',
  CategoryId? categoryId,
  Payee? payee,
  String? note,
  List<String>? attachmentIds,
}) =>
    Transaction(
      id: TransactionId(id),
      workspaceId: 'ws-1',
      accountId: const AccountId('acc-1'),
      type: TransactionType.expense,
      amount: Money(amount: Decimal.parse(amount), currency: _inr),
      categoryId: categoryId,
      payee: payee,
      note: note,
      date: TransactionDate(DateTime(2024, 6, 15)),
      attachmentIds: attachmentIds ?? const [],
      createdAt: DateTime(2024, 6, 15),
      updatedAt: DateTime(2024, 6, 15),
    );

Transaction _makeTransfer({
  String id = 'txn-transfer',
  String? counterpartId = 'txn-counterpart',
}) =>
    Transaction(
      id: TransactionId(id),
      workspaceId: 'ws-1',
      accountId: const AccountId('acc-1'),
      type: TransactionType.transfer,
      amount: Money(amount: Decimal.parse('500'), currency: _inr),
      date: TransactionDate(DateTime(2024, 6, 15)),
      transferCounterpartId:
          counterpartId != null ? TransactionId(counterpartId) : null,
      createdAt: DateTime(2024, 6, 15),
      updatedAt: DateTime(2024, 6, 15),
    );

void main() {
  group('Transaction', () {
    // ── Construction ─────────────────────────────────────────────────────────

    test('constructs an expense with required fields', () {
      final t = _makeExpense();
      expect(t.type, TransactionType.expense);
      expect(t.amount.amount, Decimal.parse('100'));
      expect(t.attachmentIds, isEmpty);
    });

    test('constructs with optional fields', () {
      final t = _makeExpense(
        categoryId: const CategoryId('cat-food'),
        payee: Payee('Zomato'),
        note: 'lunch',
        attachmentIds: ['att-1', 'att-2'],
      );
      expect(t.categoryId?.value, 'cat-food');
      expect(t.payee?.value, 'Zomato');
      expect(t.note, 'lunch');
      expect(t.attachmentIds, ['att-1', 'att-2']);
    });

    // ── Invariant 3 — amount must be positive ─────────────────────────────────

    test('rejects zero amount (Invariant 3)', () {
      expect(
        () => _makeExpense(amount: '0'),
        throwsA(isA<FinanceException>()),
      );
    });

    test('rejects negative amount (Invariant 3)', () {
      expect(
        () => _makeExpense(amount: '-50'),
        throwsA(isA<FinanceException>()),
      );
    });

    test('accepts minimal positive decimal amount', () {
      expect(() => _makeExpense(amount: '0.01'), returnsNormally);
    });

    // ── Transfer invariant — counterpartId required ───────────────────────────

    test('transfer with counterpartId constructs successfully', () {
      expect(() => _makeTransfer(counterpartId: 'txn-pair'), returnsNormally);
    });

    test('transfer without counterpartId throws (structural invariant)', () {
      expect(
        () => _makeTransfer(counterpartId: null),
        throwsA(isA<FinanceException>()),
      );
    });

    test('non-transfer without counterpartId is valid', () {
      expect(_makeExpense, returnsNormally);
    });

    // ── Identity equality ─────────────────────────────────────────────────────

    test('two transactions with the same id are equal', () {
      final a = _makeExpense(id: 'txn-1', amount: '100');
      final b = _makeExpense(id: 'txn-1', amount: '999');
      expect(a, equals(b));
    });

    test('transactions with different ids are not equal', () {
      final a = _makeExpense(id: 'txn-1');
      final b = _makeExpense(id: 'txn-2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode based on id', () {
      final a = _makeExpense(id: 'txn-1');
      final b = _makeExpense(id: 'txn-1');
      expect(a.hashCode, b.hashCode);
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith updates note', () {
      final original = _makeExpense(note: 'old');
      final updated = original.copyWith(note: 'new');
      expect(updated.note, 'new');
      expect(updated.id, original.id);
    });

    test('copyWith can set note to null', () {
      final original = _makeExpense(note: 'old');
      final updated = original.copyWith(note: null);
      expect(updated.note, isNull);
    });

    test('copyWith can set categoryId to null', () {
      final original =
          _makeExpense(categoryId: const CategoryId('cat-food'));
      final updated = original.copyWith(categoryId: null);
      expect(updated.categoryId, isNull);
    });

    test('copyWith with no arguments produces equivalent transaction', () {
      final original = _makeExpense(
        note: 'lunch',
        categoryId: const CategoryId('cat-1'),
      );
      final copy = original.copyWith();
      expect(copy, equals(original));
      expect(copy.note, original.note);
      expect(copy.categoryId, original.categoryId);
    });

    test('copyWith rejects zero amount', () {
      final original = _makeExpense(amount: '100');
      expect(
        () => original.copyWith(
          amount: Money(amount: Decimal.zero, currency: _inr),
        ),
        throwsA(isA<FinanceException>()),
      );
    });

    test('copyWith can update attachmentIds', () {
      final original = _makeExpense();
      final updated = original.copyWith(attachmentIds: ['att-1']);
      expect(updated.attachmentIds, ['att-1']);
    });

    // ── toString ─────────────────────────────────────────────────────────────

    test('toString includes id and type', () {
      final t = _makeExpense(id: 'txn-99');
      expect(t.toString(), contains('txn-99'));
      expect(t.toString(), contains('expense'));
    });
  });
}
