import 'package:feature_finance/src/data/mappers/currency_minor_units.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyMinorUnits.scaleFor', () {
    test('returns 2 for common 2-decimal currencies', () {
      expect(CurrencyMinorUnits.scaleFor('USD'), 2);
      expect(CurrencyMinorUnits.scaleFor('INR'), 2);
      expect(CurrencyMinorUnits.scaleFor('EUR'), 2);
    });

    test('returns 0 for zero-decimal currencies', () {
      expect(CurrencyMinorUnits.scaleFor('JPY'), 0);
      expect(CurrencyMinorUnits.scaleFor('KRW'), 0);
    });

    test('returns 3 for three-decimal currencies', () {
      expect(CurrencyMinorUnits.scaleFor('BHD'), 3);
      expect(CurrencyMinorUnits.scaleFor('KWD'), 3);
    });

    test('throws FinanceException for an unregistered currency code', () {
      expect(
        () => CurrencyMinorUnits.scaleFor('XYZ'),
        throwsA(isA<FinanceException>()),
      );
    });
  });
}
