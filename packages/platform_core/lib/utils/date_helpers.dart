/// Static date/time utility functions.
///
/// These are pure functions — no state, no side effects. All timezone-aware
/// operations accept explicit [DateTime] arguments rather than calling
/// [DateTime.now()] internally, making them fully testable.
abstract final class DateHelpers {
  DateHelpers._();

  /// Returns `true` if [a] and [b] fall on the same calendar day, regardless
  /// of time or timezone.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the number of whole calendar days between [from] and [to].
  ///
  /// The result is negative when [to] is before [from].
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// Parses an ISO 8601 date string (`YYYY-MM-DD`) into a [DateTime] at
  /// midnight local time.
  ///
  /// Returns `null` if [source] cannot be parsed.
  static DateTime? tryParseDate(String source) {
    try {
      final parts = source.trim().split('-');
      if (parts.length != 3) return null;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) return null;
      // Guard against Dart's silent date overflow (e.g. month 13 → next year).
      if (m < 1 || m > 12 || d < 1 || d > 31) return null;
      final date = DateTime(y, m, d);
      // A round-trip mismatch means the day overflowed (e.g. Feb 30).
      if (date.month != m || date.day != d) return null;
      return date;
    } catch (_) {
      return null;
    }
  }

  /// Returns the first [DateTime] of the ISO week containing [date].
  ///
  /// ISO weeks start on Monday (weekday == 1).
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Returns the first [DateTime] of the calendar month containing [date].
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);
}
