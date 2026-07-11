/// Generic [DateTime] extension methods with no business-domain knowledge.
extension DateTimeX on DateTime {
  /// Returns a new [DateTime] at the very start of this day (00:00:00.000).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns a new [DateTime] at the very end of this day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns `true` if this date falls on a Saturday or Sunday.
  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// Returns `true` if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns `true` if this date is strictly before today (UTC).
  bool get isPast => isBefore(DateTime.now());

  /// Returns `true` if this date is today or in the future (UTC).
  bool get isFutureOrNow => !isBefore(DateTime.now());

  /// Formats this date as `YYYY-MM-DD` (ISO 8601 date-only).
  String toIsoDateString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Returns a [DateTime] with the time component set to midnight, preserving
  /// the timezone offset of the original.
  DateTime withoutTime() => isUtc
      ? DateTime.utc(year, month, day)
      : DateTime(year, month, day);
}
