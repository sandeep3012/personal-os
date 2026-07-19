import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/data/mappers/currency_minor_units.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';

/// Centralizes all `Decimal` ↔ `INTEGER` minor-unit conversion for Money.
///
/// Per DOC-031 §6.2, amounts are persisted as `INTEGER` minor currency units
/// (e.g. paise, cents) — never as SQLite `REAL`. [AccountMapper] and
/// [TransactionMapper] both delegate here rather than duplicating the
/// conversion, and no repository performs this conversion itself.
///
/// Conversion is exact: [Decimal.shift] scales by a power of ten without any
/// floating-point rounding. If [toMinorUnits] is given an amount with more
/// precision than the currency's registered scale supports (e.g. three
/// decimal places for a 2-decimal currency), it fails explicitly rather than
/// truncating — silently rounding would discord with the persisted amount
/// the caller believes they saved.
abstract final class MoneyMinorUnitsConverter {
  /// Converts [amount] (in [currencyCode]) to its integer minor-unit
  /// representation.
  ///
  /// Throws [FinanceException] if [amount] carries more precision than
  /// [currencyCode]'s registered scale supports.
  static int toMinorUnits(Decimal amount, String currencyCode) {
    final scale = CurrencyMinorUnits.scaleFor(currencyCode);
    final shifted = amount.shift(scale);
    if (!shifted.isInteger) {
      throw FinanceException(
        message: 'Amount $amount has more precision than $currencyCode '
            'supports ($scale decimal place(s)). Refusing to convert to '
            'minor units with loss of precision.',
      );
    }
    return shifted.toBigInt().toInt();
  }

  /// Converts [minorUnits] back to a `Decimal` amount in [currencyCode].
  static Decimal fromMinorUnits(int minorUnits, String currencyCode) {
    final scale = CurrencyMinorUnits.scaleFor(currencyCode);
    return Decimal.fromBigInt(BigInt.from(minorUnits)).shift(-scale);
  }
}
