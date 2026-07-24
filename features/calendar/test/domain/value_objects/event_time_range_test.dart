import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventTimeRange construction', () {
    test('accepts an end strictly after start', () {
      final range = EventTimeRange(
        start: DateTime(2026, 1, 1, 9),
        end: DateTime(2026, 1, 1, 10),
      );
      expect(range.start, DateTime(2026, 1, 1, 9));
      expect(range.end, DateTime(2026, 1, 1, 10));
    });

    test('rejects an end equal to start', () {
      final start = DateTime(2026, 1, 1, 9);
      expect(
        () => EventTimeRange(start: start, end: start),
        throwsA(isA<CalendarException>()),
      );
    });

    test('rejects an end before start', () {
      expect(
        () => EventTimeRange(
          start: DateTime(2026, 1, 1, 10),
          end: DateTime(2026, 1, 1, 9),
        ),
        throwsA(isA<CalendarException>()),
      );
    });
  });

  group('EventTimeRange.duration', () {
    test('returns the wall-clock length of the range', () {
      final range = EventTimeRange(
        start: DateTime(2026, 1, 1, 9),
        end: DateTime(2026, 1, 1, 10, 30),
      );
      expect(range.duration, const Duration(hours: 1, minutes: 30));
    });
  });

  group('EventTimeRange equality', () {
    test('two ranges with the same start/end are equal', () {
      final a = EventTimeRange(start: DateTime(2026, 1, 1, 9), end: DateTime(2026, 1, 1, 10));
      final b = EventTimeRange(start: DateTime(2026, 1, 1, 9), end: DateTime(2026, 1, 1, 10));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
