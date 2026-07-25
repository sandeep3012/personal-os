import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';

/// The scheduled start/end of an [Event] (mirrors Tasks' `TaskDueDate`
/// value-object pattern — a domain-owned wrapper around raw [DateTime]
/// values, not a new date-handling engine).
///
/// Unlike `TaskDueDate` (a date-only value with no ordering to enforce
/// against another field), [EventTimeRange] carries two [DateTime]s and
/// enforces the one business invariant a time range needs: [end] must be
/// strictly after [start]. This is the only validation performed here —
/// no timezone handling, no recurrence, no all-day-event modeling.
final class EventTimeRange {
  EventTimeRange({required this.start, required this.end}) {
    if (!end.isAfter(start)) {
      throw const CalendarException(
        message: 'Event end time must be after start time',
      );
    }
  }

  final DateTime start;
  final DateTime end;

  /// The wall-clock length of this range.
  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventTimeRange && other.start == start && other.end == end);

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'EventTimeRange(start: $start, end: $end)';
}
