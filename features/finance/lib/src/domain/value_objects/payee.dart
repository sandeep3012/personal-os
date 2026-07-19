import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';

/// A non-empty string identifying the other party in a transaction —
/// a merchant, person, or institution.
final class Payee {
  Payee(this.value) {
    if (value.isEmpty) {
      throw const FinanceException(message: 'Payee name must not be empty');
    }
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Payee && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
