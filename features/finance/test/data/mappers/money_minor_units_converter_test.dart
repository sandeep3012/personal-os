import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/data/mappers/money_minor_units_converter.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyMinorUnitsConverter.toMinorUnits', () {
    test('converts a 2-decimal amount to minor units', () {
      expect(
        MoneyMinorUnitsConverter.toMinorUnits(Decimal.parse('125.75'), 'INR'),
        12575,
      );
    });

    test('converts a zero amount', () {
      expect(
        MoneyMinorUnitsConverter.toMinorUnits(Decimal.zero, 'USD'),
        0,
      );
    });

    test('converts a whole-number amount', () {
      expect(
        MoneyMinorUnitsConverter.toMinorUnits(Decimal.parse('50'), 'USD'),
        5000,
      );
    });

    test('converts a negative amount (e.g. credit card opening balance)', () {
      expect(
        MoneyMinorUnitsConverter.toMinorUnits(Decimal.parse('-500.00'), 'INR'),
        -50000,
      );
    });

    test('converts a very large amount without precision loss', () {
      expect(
        MoneyMinorUnitsConverter.toMinorUnits(
          Decimal.parse('999999999999.99'),
          'USD',
        ),
        99999999999999,
      );
    });

    test('converts a zero-decimal currency (JPY) with a whole number', () {
      expect(
        MoneyMinorUnitsConverter.toMinorUnits(Decimal.parse('100'), 'JPY'),
        100,
      );
    });

    test('converts a three-decimal currency (BHD)', () {
      expect(
        MoneyMinorUnitsConverter.toMinorUnits(Decimal.parse('0.100'), 'BHD'),
        100,
      );
    });

    test('throws FinanceException when amount has more precision than the '
        'currency supports', () {
      expect(
        () => MoneyMinorUnitsConverter.toMinorUnits(
          Decimal.parse('100.005'),
          'INR',
        ),
        throwsA(isA<FinanceException>()),
      );
    });

    test('throws FinanceException for an unsupported currency code', () {
      expect(
        () => MoneyMinorUnitsConverter.toMinorUnits(Decimal.parse('10'), 'XYZ'),
        throwsA(isA<FinanceException>()),
      );
    });
  });

  group('MoneyMinorUnitsConverter.fromMinorUnits', () {
    test('converts minor units back to a 2-decimal amount', () {
      expect(
        MoneyMinorUnitsConverter.fromMinorUnits(12575, 'INR'),
        Decimal.parse('125.75'),
      );
    });

    test('converts zero minor units', () {
      expect(
        MoneyMinorUnitsConverter.fromMinorUnits(0, 'USD'),
        Decimal.zero,
      );
    });

    test('converts a negative minor-unit value', () {
      expect(
        MoneyMinorUnitsConverter.fromMinorUnits(-50000, 'INR'),
        Decimal.parse('-500.00'),
      );
    });

    test('converts a very large minor-unit value without precision loss', () {
      expect(
        MoneyMinorUnitsConverter.fromMinorUnits(99999999999999, 'USD'),
        Decimal.parse('999999999999.99'),
      );
    });

    test('converts a zero-decimal currency (JPY)', () {
      expect(
        MoneyMinorUnitsConverter.fromMinorUnits(100, 'JPY'),
        Decimal.parse('100'),
      );
    });

    test('converts a three-decimal currency (BHD)', () {
      expect(
        MoneyMinorUnitsConverter.fromMinorUnits(100, 'BHD'),
        Decimal.parse('0.100'),
      );
    });

    test('round-trips toMinorUnits -> fromMinorUnits without precision loss',
        () {
      final original = Decimal.parse('4999.42');
      final minorUnits = MoneyMinorUnitsConverter.toMinorUnits(original, 'USD');
      final restored = MoneyMinorUnitsConverter.fromMinorUnits(minorUnits, 'USD');

      expect(restored, original);
    });
  });
}
