/// An immutable bounded interval between two [DateTime] values (inclusive).
///
/// Used by repository query APIs that filter records by a date window.
/// [start] must not be after [end].
final class DateRange {
  DateRange({required this.start, required this.end})
      : assert(
          !start.isAfter(end),
          'DateRange: start must not be after end',
        );

  final DateTime start;
  final DateTime end;

  /// Returns `true` when [date] falls within this range (inclusive on both
  /// ends).
  bool contains(DateTime date) =>
      !date.isBefore(start) && !date.isAfter(end);

  /// The duration from [start] to [end].
  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start – $end)';
}
