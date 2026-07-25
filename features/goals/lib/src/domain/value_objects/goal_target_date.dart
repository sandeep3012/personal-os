/// A date-only value identifying a [Goal]'s target completion date —
/// mirrors `TaskDueDate` exactly in intent and rationale.
///
/// The time-of-day component of the input [DateTime] is discarded so that
/// two [GoalTargetDate] instances for the same calendar day compare equal
/// regardless of when during that day they were constructed.
final class GoalTargetDate {
  GoalTargetDate(DateTime dateTime)
      : value = DateTime(dateTime.year, dateTime.month, dateTime.day);

  /// The date at midnight local time.
  final DateTime value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalTargetDate && other.value == value);

  @override
  int get hashCode => value.hashCode;

  /// Returns the date as `YYYY-MM-DD`.
  @override
  String toString() => '${value.year}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
