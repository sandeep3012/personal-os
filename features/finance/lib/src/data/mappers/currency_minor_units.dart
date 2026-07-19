import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';

/// ISO 4217 minor-unit (decimal place) lookup for supported currencies.
///
/// DOC-031 §6.2 requires a "simple constant map" from currency code to
/// minor-unit scale so `Money` (`Decimal`) can convert losslessly to/from the
/// `INTEGER` minor-unit columns defined by the Sprint 8B schema. Most
/// currencies use 2 decimal places; a handful of real ISO 4217 exceptions
/// use 0 or 3.
///
/// A currency code absent from this map is treated as unsupported and
/// [scaleFor] throws rather than guessing — silently defaulting an unlisted
/// code to 2 decimal places could silently corrupt amounts for a currency
/// that actually uses a different scale (e.g. `JPY` or `BHD`).
abstract final class CurrencyMinorUnits {
  static const Map<String, int> _scaleByCurrencyCode = {
    // 2 decimal places (the common case).
    'USD': 2, 'INR': 2, 'EUR': 2, 'GBP': 2, 'AUD': 2, 'CAD': 2, 'CHF': 2,
    'CNY': 2, 'SGD': 2, 'NZD': 2, 'HKD': 2, 'SEK': 2, 'NOK': 2, 'DKK': 2,
    'ZAR': 2, 'AED': 2, 'SAR': 2, 'MXN': 2, 'BRL': 2, 'PLN': 2, 'THB': 2,
    // 0 decimal places.
    'JPY': 0, 'KRW': 0, 'VND': 0, 'CLP': 0, 'ISK': 0, 'HUF': 0,
    // 3 decimal places.
    'BHD': 3, 'KWD': 3, 'OMR': 3, 'JOD': 3, 'TND': 3,
  };

  /// Returns the number of decimal places [currencyCode] uses.
  ///
  /// Throws [FinanceException] if [currencyCode] is not a registered
  /// currency — this scale table intentionally does not cover every ISO
  /// 4217 code, only those explicitly supported for Money conversion.
  static int scaleFor(String currencyCode) {
    final scale = _scaleByCurrencyCode[currencyCode];
    if (scale == null) {
      throw FinanceException(
        message: 'No minor-unit scale is registered for currency code '
            '"$currencyCode". Cannot convert Money to/from minor units for '
            'an unsupported currency.',
      );
    }
    return scale;
  }
}
