import 'package:decimal/decimal.dart';

import 'package:feature_finance/src/domain/value_objects/currency_code.dart';

/// An immutable monetary amount in a specific currency.
///
/// [amount] is represented as an exact [Decimal] to avoid floating-point
/// precision errors in financial arithmetic. The domain layer remains
/// storage-agnostic; conversion to/from minor currency units is the
/// responsibility of the repository layer (Sprint 8B).
final class Money {
  const Money({required this.amount, required this.currency});

  final Decimal amount;
  final CurrencyCode currency;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Money &&
          other.amount == amount &&
          other.currency == currency);

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => '${currency.value} $amount';
}
