import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/services/category_summary_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');
final _usd = CurrencyCode('USD');

int _idSeq = 0;

Money _money(String amount, {CurrencyCode? currency}) =>
    Money(amount: Decimal.parse(amount), currency: currency ?? _inr);

Transaction _expense(
  String amount, {
  CategoryId? categoryId,
  CurrencyCode? currency,
}) =>
    Transaction(
      id: TransactionId('t-${++_idSeq}'),
      workspaceId: 'ws-1',
      accountId: const AccountId('acc-1'),
      type: TransactionType.expense,
      amount: _money(amount, currency: currency),
      categoryId: categoryId,
      date: TransactionDate(DateTime(2024, 6, 1)),
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

Transaction _income(String amount) => Transaction(
      id: TransactionId('t-${++_idSeq}'),
      workspaceId: 'ws-1',
      accountId: const AccountId('acc-1'),
      type: TransactionType.income,
      amount: _money(amount),
      date: TransactionDate(DateTime(2024, 6, 1)),
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

Transaction _transferLeg(String amount) => Transaction(
      id: TransactionId('t-${++_idSeq}'),
      workspaceId: 'ws-1',
      accountId: const AccountId('acc-1'),
      type: TransactionType.expense,
      amount: _money(amount),
      date: TransactionDate(DateTime(2024, 6, 1)),
      transferCounterpartId: const TransactionId('counterpart'),
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const service = CategorySummaryService();
  const food = CategoryId('cat-food');
  const transport = CategoryId('cat-transport');

  setUp(() => _idSeq = 0);

  group('CategorySummaryService', () {
    test('empty transaction list returns an empty map', () {
      expect(service.summarizeByCategory([]), isEmpty);
    });

    test('single categorised expense appears in the result', () {
      final result = service.summarizeByCategory([
        _expense('150', categoryId: food),
      ]);
      expect(result.containsKey(food), isTrue);
      expect(result[food]!.amount, Decimal.parse('150'));
    });

    test('multiple expenses with the same category are summed', () {
      final result = service.summarizeByCategory([
        _expense('100', categoryId: food),
        _expense('75', categoryId: food),
        _expense('25', categoryId: food),
      ]);
      expect(result[food]!.amount, Decimal.parse('200'));
    });

    test('expenses with different categories produce separate map entries', () {
      final result = service.summarizeByCategory([
        _expense('300', categoryId: food),
        _expense('150', categoryId: transport),
      ]);
      expect(result[food]!.amount, Decimal.parse('300'));
      expect(result[transport]!.amount, Decimal.parse('150'));
    });

    test('income transactions are excluded from the summary', () {
      final result = service.summarizeByCategory([
        _expense('100', categoryId: food),
        _income('500'),
      ]);
      expect(result.length, 1);
      expect(result[food]!.amount, Decimal.parse('100'));
    });

    test('transfer legs (expense type, no category) are excluded', () {
      final result = service.summarizeByCategory([
        _expense('100', categoryId: food),
        _transferLeg('200'),
      ]);
      expect(result.length, 1);
      expect(result[food]!.amount, Decimal.parse('100'));
    });

    test('expenses without a categoryId are excluded', () {
      final result = service.summarizeByCategory([
        _expense('200'),
        _expense('100', categoryId: food),
      ]);
      expect(result.length, 1);
      expect(result[food]!.amount, Decimal.parse('100'));
    });

    test('result preserves Decimal precision', () {
      final result = service.summarizeByCategory([
        _expense('0.1', categoryId: food),
        _expense('0.2', categoryId: food),
      ]);
      expect(result[food]!.amount, Decimal.parse('0.3'));
    });

    test('currency mismatch within the same category throws FinanceException',
        () {
      expect(
        () => service.summarizeByCategory([
          _expense('100', categoryId: food, currency: _inr),
          _expense('50', categoryId: food, currency: _usd),
        ]),
        throwsA(isA<FinanceException>()),
      );
    });

    test('result currency matches the expense currency', () {
      final result = service.summarizeByCategory([
        _expense('100', categoryId: food),
      ]);
      expect(result[food]!.currency, _inr);
    });

    test('mixed categorised and uncategorised expenses: only categorised appear',
        () {
      final result = service.summarizeByCategory([
        _expense('500'),
        _expense('200', categoryId: food),
        _expense('100', categoryId: transport),
        _income('1000'),
      ]);
      expect(result.length, 2);
    });
  });
}
