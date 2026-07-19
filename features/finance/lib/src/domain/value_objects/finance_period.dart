import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';

/// A calendar month used for grouping and reporting transactions.
///
/// [month] is 1-based (1 = January, 12 = December).
final class FinancePeriod {
  FinancePeriod({required this.year, required this.month}) {
    if (month < 1 || month > 12) {
      throw FinanceException(
        message: 'FinancePeriod: month must be 1–12, got $month',
      );
    }
  }

  final int year;

  /// 1-based month number (1 = January … 12 = December).
  final int month;

  /// Creates a [FinancePeriod] from the month containing [dateTime].
  factory FinancePeriod.fromDateTime(DateTime dateTime) =>
      FinancePeriod(year: dateTime.year, month: dateTime.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancePeriod && other.year == year && other.month == month);

  @override
  int get hashCode => Object.hash(year, month);

  /// Returns the period as `YYYY-MM`.
  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}
