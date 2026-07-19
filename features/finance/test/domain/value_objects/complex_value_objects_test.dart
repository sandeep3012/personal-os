import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── CurrencyCode ──────────────────────────────────────────────────────────

  group('CurrencyCode', () {
    test('accepts valid 3-letter uppercase code', () {
      expect(CurrencyCode('INR').value, 'INR');
      expect(CurrencyCode('USD').value, 'USD');
    });

    test('rejects lowercase code', () {
      expect(() => CurrencyCode('inr'), throwsA(isA<FinanceException>()));
    });

    test('rejects code shorter than 3 letters', () {
      expect(() => CurrencyCode('US'), throwsA(isA<FinanceException>()));
    });

    test('rejects code longer than 3 letters', () {
      expect(() => CurrencyCode('USDD'), throwsA(isA<FinanceException>()));
    });

    test('rejects code with digits', () {
      expect(() => CurrencyCode('US1'), throwsA(isA<FinanceException>()));
    });

    test('equality by value', () {
      expect(CurrencyCode('INR'), equals(CurrencyCode('INR')));
    });

    test('inequality for different codes', () {
      expect(CurrencyCode('INR'), isNot(equals(CurrencyCode('USD'))));
    });

    test('hash consistent with equality', () {
      expect(CurrencyCode('INR').hashCode, CurrencyCode('INR').hashCode);
    });

    test('toString returns the code', () {
      expect(CurrencyCode('EUR').toString(), 'EUR');
    });
  });

  // ── Money ─────────────────────────────────────────────────────────────────

  group('Money', () {
    final inr = CurrencyCode('INR');
    final usd = CurrencyCode('USD');
    final amount = Decimal.parse('125.75');

    test('stores amount and currency', () {
      final money = Money(amount: amount, currency: inr);
      expect(money.amount, amount);
      expect(money.currency, inr);
    });

    test('equality by amount and currency', () {
      final a = Money(amount: Decimal.parse('100'), currency: inr);
      final b = Money(amount: Decimal.parse('100'), currency: inr);
      expect(a, equals(b));
    });

    test('inequality when amounts differ', () {
      final a = Money(amount: Decimal.parse('100'), currency: inr);
      final b = Money(amount: Decimal.parse('200'), currency: inr);
      expect(a, isNot(equals(b)));
    });

    test('inequality when currencies differ', () {
      final a = Money(amount: Decimal.parse('100'), currency: inr);
      final b = Money(amount: Decimal.parse('100'), currency: usd);
      expect(a, isNot(equals(b)));
    });

    test('hash consistent with equality', () {
      final a = Money(amount: amount, currency: inr);
      final b = Money(amount: amount, currency: inr);
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes currency and amount', () {
      final money = Money(amount: Decimal.parse('125.75'), currency: inr);
      expect(money.toString(), 'INR 125.75');
    });

    test('Decimal preserves precision', () {
      final a = Money(amount: Decimal.parse('0.1'), currency: inr);
      final b = Money(amount: Decimal.parse('0.2'), currency: inr);
      // Verify that Decimal arithmetic is exact (unlike double).
      expect(a.amount + b.amount, Decimal.parse('0.3'));
    });
  });

  // ── Payee ─────────────────────────────────────────────────────────────────

  group('Payee', () {
    test('stores non-empty value', () {
      expect(Payee('Swiggy').value, 'Swiggy');
    });

    test('rejects empty string', () {
      expect(() => Payee(''), throwsA(isA<FinanceException>()));
    });

    test('equality by value', () {
      expect(Payee('Amazon'), equals(Payee('Amazon')));
    });

    test('inequality for different payees', () {
      expect(Payee('Amazon'), isNot(equals(Payee('Flipkart'))));
    });

    test('hash consistent with equality', () {
      expect(Payee('x').hashCode, Payee('x').hashCode);
    });

    test('toString returns the name', () {
      expect(Payee('Netflix').toString(), 'Netflix');
    });
  });

  // ── TransactionDate ───────────────────────────────────────────────────────

  group('TransactionDate', () {
    test('strips time component', () {
      final d = TransactionDate(DateTime(2024, 6, 15, 14, 30, 45));
      expect(d.value, DateTime(2024, 6, 15));
    });

    test('two dates on the same calendar day are equal', () {
      final a = TransactionDate(DateTime(2024, 6, 15, 9, 0));
      final b = TransactionDate(DateTime(2024, 6, 15, 23, 59));
      expect(a, equals(b));
    });

    test('dates on different days are not equal', () {
      final a = TransactionDate(DateTime(2024, 6, 15));
      final b = TransactionDate(DateTime(2024, 6, 16));
      expect(a, isNot(equals(b)));
    });

    test('hash consistent with equality', () {
      final a = TransactionDate(DateTime(2024, 6, 15, 8));
      final b = TransactionDate(DateTime(2024, 6, 15, 20));
      expect(a.hashCode, b.hashCode);
    });

    test('toString returns YYYY-MM-DD', () {
      expect(
        TransactionDate(DateTime(2024, 6, 5)).toString(),
        '2024-06-05',
      );
    });

    test('toString pads single-digit month and day', () {
      expect(
        TransactionDate(DateTime(2024, 1, 9)).toString(),
        '2024-01-09',
      );
    });
  });

  // ── FinancePeriod ─────────────────────────────────────────────────────────

  group('FinancePeriod', () {
    test('stores year and month', () {
      final p = FinancePeriod(year: 2024, month: 6);
      expect(p.year, 2024);
      expect(p.month, 6);
    });

    test('rejects month 0', () {
      expect(
        () => FinancePeriod(year: 2024, month: 0),
        throwsA(isA<FinanceException>()),
      );
    });

    test('rejects month 13', () {
      expect(
        () => FinancePeriod(year: 2024, month: 13),
        throwsA(isA<FinanceException>()),
      );
    });

    test('accepts boundary months 1 and 12', () {
      expect(() => FinancePeriod(year: 2024, month: 1), returnsNormally);
      expect(() => FinancePeriod(year: 2024, month: 12), returnsNormally);
    });

    test('fromDateTime factory extracts correct period', () {
      final p = FinancePeriod.fromDateTime(DateTime(2024, 6, 15));
      expect(p.year, 2024);
      expect(p.month, 6);
    });

    test('equality by year and month', () {
      expect(
        FinancePeriod(year: 2024, month: 6),
        equals(FinancePeriod(year: 2024, month: 6)),
      );
    });

    test('inequality when year differs', () {
      expect(
        FinancePeriod(year: 2024, month: 6),
        isNot(equals(FinancePeriod(year: 2025, month: 6))),
      );
    });

    test('inequality when month differs', () {
      expect(
        FinancePeriod(year: 2024, month: 6),
        isNot(equals(FinancePeriod(year: 2024, month: 7))),
      );
    });

    test('hash consistent with equality', () {
      expect(
        FinancePeriod(year: 2024, month: 6).hashCode,
        FinancePeriod(year: 2024, month: 6).hashCode,
      );
    });

    test('toString returns YYYY-MM', () {
      expect(FinancePeriod(year: 2024, month: 6).toString(), '2024-06');
    });

    test('toString pads single-digit month', () {
      expect(FinancePeriod(year: 2024, month: 1).toString(), '2024-01');
    });
  });
}
