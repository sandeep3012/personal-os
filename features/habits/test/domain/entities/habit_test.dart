import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

Habit _habit({
  HabitStatus status = HabitStatus.active,
  HabitFrequency frequency = HabitFrequency.daily,
  String name = 'Drink water',
  int currentStreak = 0,
  int longestStreak = 0,
  List<DateTime>? completionLog,
  DateTime? lastCompletedAt,
}) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    id: const HabitId('habit-1'),
    workspaceId: _ws,
    name: name,
    frequency: frequency,
    status: status,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    completionLog: completionLog,
    lastCompletedAt: lastCompletedAt,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Habit construction', () {
    test('throws when name is empty', () {
      expect(() => _habit(name: ''), throwsA(isA<HabitsException>()));
    });

    test('throws when name is only whitespace', () {
      expect(() => _habit(name: '   '), throwsA(isA<HabitsException>()));
    });

    test('throws when name exceeds 200 characters', () {
      expect(() => _habit(name: 'a' * 201), throwsA(isA<HabitsException>()));
    });

    test('accepts a name at exactly 200 characters', () {
      expect(() => _habit(name: 'a' * 200), returnsNormally);
    });

    test('throws when currentStreak is negative', () {
      expect(() => _habit(currentStreak: -1), throwsA(isA<HabitsException>()));
    });

    test('throws when longestStreak is negative', () {
      expect(() => _habit(longestStreak: -1), throwsA(isA<HabitsException>()));
    });

    test('defaults to zero streaks and an empty completion log', () {
      final habit = _habit();
      expect(habit.currentStreak, 0);
      expect(habit.longestStreak, 0);
      expect(habit.completionLog, isEmpty);
      expect(habit.lastCompletedAt, isNull);
    });
  });

  group('Habit.transitionTo', () {
    test('active -> archived succeeds', () {
      final habit = _habit();
      final result = habit.transitionTo(HabitStatus.archived, now: DateTime(2026, 1, 2));
      expect(result.status, HabitStatus.archived);
    });

    test('archived cannot transition anywhere (terminal)', () {
      final habit = _habit(status: HabitStatus.archived);
      expect(
        () => habit.transitionTo(HabitStatus.active, now: DateTime(2026, 1, 2)),
        throwsA(isA<HabitsException>()),
      );
    });

    test('cannot transition to the same status', () {
      final habit = _habit();
      expect(
        () => habit.transitionTo(HabitStatus.active, now: DateTime(2026, 1, 2)),
        throwsA(isA<HabitsException>()),
      );
    });

    test('preserves streak/completion state across a transition', () {
      final habit = _habit(
        currentStreak: 3,
        longestStreak: 5,
        completionLog: [DateTime(2025, 12, 31)],
        lastCompletedAt: DateTime(2025, 12, 31),
      );
      final archived = habit.transitionTo(HabitStatus.archived, now: DateTime(2026, 1, 2));
      expect(archived.currentStreak, 3);
      expect(archived.longestStreak, 5);
      expect(archived.completionLog, [DateTime(2025, 12, 31)]);
    });
  });

  group('Habit.recordCompletion — streak continuation', () {
    test('first-ever completion starts a streak of 1', () {
      final habit = _habit();
      final result = habit.recordCompletion(DateTime(2026, 1, 1), now: DateTime(2026, 1, 1));
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.lastCompletedAt, DateTime(2026, 1, 1));
      expect(result.completionLog, [DateTime(2026, 1, 1)]);
    });

    test('daily habit: completing the following day continues the streak', () {
      final habit = _habit(
        currentStreak: 2,
        longestStreak: 2,
        completionLog: [DateTime(2026, 1, 1), DateTime(2026, 1, 2)],
        lastCompletedAt: DateTime(2026, 1, 2),
      );
      final result = habit.recordCompletion(DateTime(2026, 1, 3), now: DateTime(2026, 1, 3));
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
    });

    test('daily habit: completing after a 2-day gap resets the streak to 1', () {
      final habit = _habit(
        currentStreak: 5,
        longestStreak: 5,
        completionLog: [DateTime(2026, 1, 1)],
        lastCompletedAt: DateTime(2026, 1, 1),
      );
      final result = habit.recordCompletion(DateTime(2026, 1, 4), now: DateTime(2026, 1, 4));
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 5, reason: 'longest streak never decreases');
    });

    test('weekly habit: completing 7 days later continues the streak', () {
      final habit = _habit(
        frequency: HabitFrequency.weekly,
        currentStreak: 1,
        longestStreak: 1,
        completionLog: [DateTime(2026, 1, 1)],
        lastCompletedAt: DateTime(2026, 1, 1),
      );
      final result = habit.recordCompletion(DateTime(2026, 1, 8), now: DateTime(2026, 1, 8));
      expect(result.currentStreak, 2);
    });

    test('weekly habit: completing after an 8-day gap resets the streak', () {
      final habit = _habit(
        frequency: HabitFrequency.weekly,
        currentStreak: 3,
        longestStreak: 3,
        completionLog: [DateTime(2026, 1, 1)],
        lastCompletedAt: DateTime(2026, 1, 1),
      );
      final result = habit.recordCompletion(DateTime(2026, 1, 9), now: DateTime(2026, 1, 9));
      expect(result.currentStreak, 1);
    });

    test('longestStreak rises to match a new record streak', () {
      final habit = _habit(
        currentStreak: 2,
        longestStreak: 4,
        completionLog: [DateTime(2026, 1, 1), DateTime(2026, 1, 2)],
        lastCompletedAt: DateTime(2026, 1, 2),
      );
      final r1 = habit.recordCompletion(DateTime(2026, 1, 3), now: DateTime(2026, 1, 3));
      final r2 = r1.recordCompletion(DateTime(2026, 1, 4), now: DateTime(2026, 1, 4));
      final r3 = r2.recordCompletion(DateTime(2026, 1, 5), now: DateTime(2026, 1, 5));
      expect(r3.currentStreak, 5);
      expect(r3.longestStreak, 5);
    });

    test('discards the time-of-day component when recording', () {
      final habit = _habit();
      final result = habit.recordCompletion(
        DateTime(2026, 1, 1, 23, 59),
        now: DateTime(2026, 1, 1, 23, 59),
      );
      expect(result.lastCompletedAt, DateTime(2026, 1, 1));
    });

    test('throws when completing the same calendar day twice', () {
      final habit = _habit(
        currentStreak: 1,
        longestStreak: 1,
        completionLog: [DateTime(2026, 1, 1)],
        lastCompletedAt: DateTime(2026, 1, 1),
      );
      expect(
        () => habit.recordCompletion(DateTime(2026, 1, 1, 8), now: DateTime(2026, 1, 1, 8)),
        throwsA(isA<HabitsException>()),
      );
    });

    test('throws when recording a completion for an archived habit', () {
      final habit = _habit(status: HabitStatus.archived);
      expect(
        () => habit.recordCompletion(DateTime(2026, 1, 2), now: DateTime(2026, 1, 2)),
        throwsA(isA<HabitsException>()),
      );
    });
  });

  group('Habit.copyWith', () {
    test('does not change status or streak/completion state', () {
      final habit = _habit(currentStreak: 3, longestStreak: 5);
      final updated = habit.copyWith(name: 'Renamed');
      expect(updated.status, HabitStatus.active);
      expect(updated.name, 'Renamed');
      expect(updated.currentStreak, 3);
      expect(updated.longestStreak, 5);
    });

    test('updates frequency when supplied', () {
      final habit = _habit();
      final updated = habit.copyWith(frequency: HabitFrequency.weekly);
      expect(updated.frequency, HabitFrequency.weekly);
    });
  });

  group('Habit equality', () {
    test('two habits with the same id are equal regardless of other fields', () {
      final now = DateTime(2026, 1, 1);
      final a = Habit(
        id: const HabitId('habit-1'),
        workspaceId: _ws,
        name: 'A',
        frequency: HabitFrequency.daily,
        status: HabitStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final b = Habit(
        id: const HabitId('habit-1'),
        workspaceId: _ws,
        name: 'B',
        frequency: HabitFrequency.weekly,
        status: HabitStatus.archived,
        createdAt: now,
        updatedAt: now,
      );
      expect(a, b);
    });
  });
}
