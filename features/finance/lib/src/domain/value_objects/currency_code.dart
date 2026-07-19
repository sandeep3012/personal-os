import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';

/// ISO 4217 three-letter currency code (e.g. `'INR'`, `'USD'`, `'EUR'`).
///
/// The value must be exactly three uppercase ASCII letters.
final class CurrencyCode {
  CurrencyCode(this.value) {
    if (!_pattern.hasMatch(value)) {
      throw FinanceException(
        message: 'CurrencyCode must be a 3-letter ISO 4217 code, got "$value"',
      );
    }
  }

  final String value;

  static final _pattern = RegExp(r'^[A-Z]{3}$');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CurrencyCode && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
