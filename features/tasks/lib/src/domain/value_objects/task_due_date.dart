/// A date-only value identifying a [Task]'s due date (DOC-032 §6.2).
///
/// Unlike Finance's `TransactionDate`, this value object imposes **no**
/// range restriction (no "not more than N days in the future" rule) — DOC-032
/// §5.3/§6.2 deliberately does not carry over that Finance-specific business
/// rule, since a far-future task due date is not an analogous data-entry
/// error the way a far-future financial transaction is.
///
/// The time-of-day component of the input [DateTime] is discarded so that
/// two [TaskDueDate] instances for the same calendar day compare equal
/// regardless of when during that day they were constructed — mirrors
/// `TransactionDate`'s exact rationale.
final class TaskDueDate {
  TaskDueDate(DateTime dateTime)
      : value = DateTime(dateTime.year, dateTime.month, dateTime.day);

  /// The date at midnight local time.
  final DateTime value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TaskDueDate && other.value == value);

  @override
  int get hashCode => value.hashCode;

  /// Returns the date as `YYYY-MM-DD`.
  @override
  String toString() =>
      '${value.year}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
