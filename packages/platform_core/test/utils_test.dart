import 'package:platform_core/extensions/date_time_extensions.dart';
import 'package:platform_core/extensions/iterable_extensions.dart';
import 'package:platform_core/extensions/string_extensions.dart';
import 'package:platform_core/utils/date_helpers.dart';
import 'package:platform_core/utils/date_range.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_core/utils/validation_helpers.dart';
import 'package:test/test.dart';

void main() {
  // ── DateRange ────────────────────────────────────────────────────────────

  group('DateRange', () {
    final jan1 = DateTime(2024, 1, 1);
    final jan15 = DateTime(2024, 1, 15);
    final jan31 = DateTime(2024, 1, 31);

    test('constructs with valid start and end', () {
      final range = DateRange(start: jan1, end: jan31);
      expect(range.start, jan1);
      expect(range.end, jan31);
    });

    test('start equal to end is valid (single-day range)', () {
      expect(() => DateRange(start: jan15, end: jan15), returnsNormally);
    });

    test('start after end throws assertion error', () {
      expect(
        () => DateRange(start: jan31, end: jan1),
        throwsA(isA<AssertionError>()),
      );
    });

    group('contains', () {
      late DateRange range;
      setUp(() => range = DateRange(start: jan1, end: jan31));

      test('returns true for date equal to start', () {
        expect(range.contains(jan1), isTrue);
      });

      test('returns true for date equal to end', () {
        expect(range.contains(jan31), isTrue);
      });

      test('returns true for date inside range', () {
        expect(range.contains(jan15), isTrue);
      });

      test('returns false for date before start', () {
        expect(range.contains(DateTime(2023, 12, 31)), isFalse);
      });

      test('returns false for date after end', () {
        expect(range.contains(DateTime(2024, 2, 1)), isFalse);
      });
    });

    test('duration returns correct difference', () {
      final range = DateRange(start: jan1, end: jan31);
      expect(range.duration.inDays, 30);
    });

    test('equality holds for same start and end', () {
      final a = DateRange(start: jan1, end: jan31);
      final b = DateRange(start: jan1, end: jan31);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when start differs', () {
      final a = DateRange(start: jan1, end: jan31);
      final b = DateRange(start: jan15, end: jan31);
      expect(a, isNot(equals(b)));
    });

    test('inequality when end differs', () {
      final a = DateRange(start: jan1, end: jan15);
      final b = DateRange(start: jan1, end: jan31);
      expect(a, isNot(equals(b)));
    });

    test('toString includes start and end', () {
      final range = DateRange(start: jan1, end: jan31);
      final s = range.toString();
      expect(s.contains('DateRange'), isTrue);
    });
  });

  // ── UuidGenerator ────────────────────────────────────────────────────────

  group('UuidGenerator', () {
    const gen = UuidGenerator();

    test('generates a string in UUID v4 format', () {
      final id = gen.generate();
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuidRegex.hasMatch(id), isTrue, reason: 'Got: $id');
    });

    test('generates unique values', () {
      final ids = {for (var i = 0; i < 100; i++) gen.generate()};
      expect(ids.length, 100);
    });
  });

  // ── DateHelpers ──────────────────────────────────────────────────────────

  group('DateHelpers', () {
    group('isSameDay', () {
      test('same date returns true', () {
        final d = DateTime(2024, 6, 15, 10, 30);
        expect(DateHelpers.isSameDay(d, DateTime(2024, 6, 15, 23, 59)), isTrue);
      });

      test('different date returns false', () {
        final a = DateTime(2024, 6, 15);
        final b = DateTime(2024, 6, 16);
        expect(DateHelpers.isSameDay(a, b), isFalse);
      });
    });

    group('daysBetween', () {
      test('positive forward difference', () {
        final from = DateTime(2024, 1, 1);
        final to = DateTime(2024, 1, 11);
        expect(DateHelpers.daysBetween(from, to), 10);
      });

      test('negative backward difference', () {
        final from = DateTime(2024, 1, 11);
        final to = DateTime(2024, 1, 1);
        expect(DateHelpers.daysBetween(from, to), -10);
      });

      test('same day returns zero', () {
        final d = DateTime(2024, 3, 5);
        expect(DateHelpers.daysBetween(d, d), 0);
      });
    });

    group('tryParseDate', () {
      test('parses valid ISO date', () {
        final result = DateHelpers.tryParseDate('2024-06-15');
        expect(result, DateTime(2024, 6, 15));
      });

      test('returns null for invalid string', () {
        expect(DateHelpers.tryParseDate('not-a-date'), isNull);
        expect(DateHelpers.tryParseDate('2024-13-01'), isNull);
        expect(DateHelpers.tryParseDate(''), isNull);
      });
    });

    group('startOfWeek', () {
      test('Monday stays Monday', () {
        final monday = DateTime(2024, 6, 10); // known Monday
        expect(DateHelpers.startOfWeek(monday), DateTime(2024, 6, 10));
      });

      test('Wednesday returns previous Monday', () {
        final wednesday = DateTime(2024, 6, 12);
        expect(DateHelpers.startOfWeek(wednesday), DateTime(2024, 6, 10));
      });
    });

    group('startOfMonth', () {
      test('returns first day of month', () {
        expect(
          DateHelpers.startOfMonth(DateTime(2024, 6, 25)),
          DateTime(2024, 6, 1),
        );
      });
    });
  });

  // ── ValidationHelpers ────────────────────────────────────────────────────

  group('ValidationHelpers', () {
    group('required', () {
      test('returns null for non-empty value', () {
        expect(ValidationHelpers.required('hello'), isNull);
      });
      test('returns error for empty', () {
        expect(ValidationHelpers.required(''), isNotNull);
      });
      test('returns error for null', () {
        expect(ValidationHelpers.required(null), isNotNull);
      });
      test('returns error for whitespace only', () {
        expect(ValidationHelpers.required('   '), isNotNull);
      });
    });

    group('maxLength', () {
      test('returns null when within limit', () {
        expect(ValidationHelpers.maxLength('hello', 10), isNull);
      });
      test('returns error when over limit', () {
        expect(ValidationHelpers.maxLength('hello world', 5), isNotNull);
      });
    });

    group('minLength', () {
      test('returns null when meeting minimum', () {
        expect(ValidationHelpers.minLength('hello', 3), isNull);
      });
      test('returns error when below minimum', () {
        expect(ValidationHelpers.minLength('hi', 5), isNotNull);
      });
    });

    group('email', () {
      test('accepts valid email', () {
        expect(ValidationHelpers.email('user@example.com'), isNull);
      });
      test('rejects invalid email', () {
        expect(ValidationHelpers.email('not-an-email'), isNotNull);
        expect(ValidationHelpers.email(''), isNotNull);
        expect(ValidationHelpers.email(null), isNotNull);
      });
    });

    group('uuid', () {
      const valid = 'a1b2c3d4-e5f6-4789-8abc-def012345678';
      test('accepts valid UUID v4', () {
        expect(ValidationHelpers.uuid(valid), isNull);
      });
      test('rejects malformed UUID', () {
        expect(ValidationHelpers.uuid('not-a-uuid'), isNotNull);
        expect(ValidationHelpers.uuid(null), isNotNull);
      });
    });

    group('numberRange', () {
      test('accepts value within range', () {
        expect(
          ValidationHelpers.numberRange('5', min: 1, max: 10),
          isNull,
        );
      });
      test('rejects value outside range', () {
        expect(
          ValidationHelpers.numberRange('11', min: 1, max: 10),
          isNotNull,
        );
      });
      test('rejects non-numeric', () {
        expect(
          ValidationHelpers.numberRange('abc', min: 1, max: 10),
          isNotNull,
        );
      });
    });
  });

  // ── StringX ──────────────────────────────────────────────────────────────

  group('StringX', () {
    test('isBlank on whitespace', () => expect('  '.isBlank, isTrue));
    test('isBlank on empty', () => expect(''.isBlank, isTrue));
    test('isNotBlank on content', () => expect('x'.isNotBlank, isTrue));
    test('nullIfBlank returns null for blank', () {
      expect(''.nullIfBlank, isNull);
    });
    test('nullIfBlank returns value for non-blank', () {
      expect('hello'.nullIfBlank, 'hello');
    });
    test('capitalised', () => expect('hello'.capitalised, 'Hello'));
    test('toTitleCase from snake_case', () {
      expect('build_environment'.toTitleCase(), 'Build Environment');
    });
    test('truncate shortens long string', () {
      expect('hello world'.truncate(5), 'hello…');
    });
    test('truncate keeps short string', () {
      expect('hi'.truncate(5), 'hi');
    });
    test('isValidEmail accepts valid', () {
      expect('a@b.com'.isValidEmail, isTrue);
    });
    test('isValidEmail rejects invalid', () {
      expect('not-email'.isValidEmail, isFalse);
    });
  });

  // ── IterableX ────────────────────────────────────────────────────────────

  group('IterableX', () {
    test('firstWhereOrNull returns matching element', () {
      expect([1, 2, 3].firstWhereOrNull((e) => e == 2), 2);
    });
    test('firstWhereOrNull returns null when not found', () {
      expect([1, 2, 3].firstWhereOrNull((e) => e == 9), isNull);
    });
    test('isSingleton true for one element', () {
      expect([42].isSingleton, isTrue);
    });
    test('isSingleton false for multiple', () {
      expect([1, 2].isSingleton, isFalse);
    });
    test('distinct removes duplicates preserving order', () {
      expect([1, 2, 1, 3, 2].distinct(), [1, 2, 3]);
    });
    test('chunked splits into equal groups', () {
      expect([1, 2, 3, 4].chunked(2).toList(), [
        [1, 2],
        [3, 4],
      ]);
    });
    test('chunked handles remainder', () {
      expect([1, 2, 3].chunked(2).toList(), [
        [1, 2],
        [3],
      ]);
    });
    test('associateBy keys by result of selector', () {
      final result = ['a', 'bb', 'ccc'].associateBy((s) => s.length);
      expect(result[1], 'a');
      expect(result[2], 'bb');
      expect(result[3], 'ccc');
    });
  });

  // ── DateTimeX ────────────────────────────────────────────────────────────

  group('DateTimeX', () {
    final saturday = DateTime(2024, 6, 15); // known Saturday
    final monday = DateTime(2024, 6, 10); // known Monday

    test('startOfDay returns midnight', () {
      final d = DateTime(2024, 6, 15, 14, 30, 45);
      expect(d.startOfDay, DateTime(2024, 6, 15));
    });

    test('endOfDay returns 23:59:59.999', () {
      expect(
        saturday.endOfDay,
        DateTime(2024, 6, 15, 23, 59, 59, 999),
      );
    });

    test('isWeekend true for Saturday', () {
      expect(saturday.isWeekend, isTrue);
    });

    test('isWeekend false for Monday', () {
      expect(monday.isWeekend, isFalse);
    });

    test('isSameDay true for same day at different times', () {
      final a = DateTime(2024, 6, 15, 9);
      final b = DateTime(2024, 6, 15, 20);
      expect(a.isSameDay(b), isTrue);
    });

    test('toIsoDateString formats correctly', () {
      expect(DateTime(2024, 6, 5).toIsoDateString(), '2024-06-05');
    });

    test('withoutTime strips time', () {
      final d = DateTime(2024, 6, 15, 14, 30);
      expect(d.withoutTime(), DateTime(2024, 6, 15));
    });
  });
}
