import 'package:feature_habits/src/data/mappers/habit_mapper.dart';
import 'package:feature_habits/src/data/models/habit_row.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = HabitMapper();

  Habit habit({
    String id = 'habit-1',
    String name = 'Drink water',
    HabitFrequency frequency = HabitFrequency.daily,
    HabitStatus status = HabitStatus.active,
    String? description,
    int currentStreak = 0,
    int longestStreak = 0,
    List<DateTime>? completionLog,
    DateTime? lastCompletedAt,
  }) {
    final now = DateTime(2024, 1, 1, 10, 30);
    return Habit(
      id: HabitId(id),
      workspaceId: 'ws-1',
      name: name,
      frequency: frequency,
      status: status,
      description: description,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionLog: completionLog,
      lastCompletedAt: lastCompletedAt,
      createdAt: now,
      updatedAt: DateTime(2024, 2, 1, 8),
    );
  }

  group('HabitMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(habit(id: 'habit-1', name: 'Drink water'));

      expect(row.habitId, 'habit-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.name, 'Drink water');
      expect(row.status, 'active');
      expect(row.frequency, 'daily');
    });

    test('maps every HabitStatus to its enum name', () {
      for (final status in HabitStatus.values) {
        final row = mapper.toRow(habit(status: status));
        expect(row.status, status.name);
      }
    });

    test('maps every HabitFrequency to its enum name', () {
      for (final frequency in HabitFrequency.values) {
        final row = mapper.toRow(habit(frequency: frequency));
        expect(row.frequency, frequency.name);
      }
    });

    test('maps the completion log to date-only ISO strings', () {
      final row = mapper.toRow(habit(
        completionLog: [DateTime(2026, 3, 1), DateTime(2026, 3, 2)],
      ));
      expect(row.completionLog, ['2026-03-01', '2026-03-02']);
    });

    test('always maps deletedAt to null (domain Habit is never soft-deleted)',
        () {
      final row = mapper.toRow(habit());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode names', () {
      final row = mapper.toRow(habit(name: 'Café run ☕ 買い物'));
      expect(row.name, 'Café run ☕ 買い物');
    });
  });

  group('HabitMapper.toEntity', () {
    HabitRow row({
      String id = 'habit-1',
      String name = 'Drink water',
      String status = 'active',
      String frequency = 'daily',
      int currentStreak = 0,
      int longestStreak = 0,
      List<String> completionLog = const [],
      DateTime? lastCompletedAt,
    }) {
      final now = DateTime(2024, 1, 1, 10, 30);
      return HabitRow(
        habitId: id,
        workspaceId: 'ws-1',
        name: name,
        frequency: frequency,
        status: status,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        completionLog: completionLog,
        lastCompletedAt: lastCompletedAt,
        createdAt: now,
        updatedAt: DateTime(2024, 2, 1, 8),
      );
    }

    test('maps all scalar fields', () {
      final habit = mapper.toEntity(row(id: 'habit-2', name: 'Meditate'));

      expect(habit.id, const HabitId('habit-2'));
      expect(habit.workspaceId, 'ws-1');
      expect(habit.name, 'Meditate');
    });

    test('converts every status column value back to its enum', () {
      for (final status in HabitStatus.values) {
        final habit = mapper.toEntity(row(status: status.name));
        expect(habit.status, status);
      }
    });

    test('converts every frequency column value back to its enum', () {
      for (final frequency in HabitFrequency.values) {
        final habit = mapper.toEntity(row(frequency: frequency.name));
        expect(habit.frequency, frequency);
      }
    });

    test('throws HabitsException for an unrecognized status value', () {
      expect(
        () => mapper.toEntity(row(status: 'not_a_real_status')),
        throwsA(isA<HabitsException>()),
      );
    });

    test('throws HabitsException for an unrecognized frequency value', () {
      expect(
        () => mapper.toEntity(row(frequency: 'not_a_real_frequency')),
        throwsA(isA<HabitsException>()),
      );
    });

    test('converts the completion log strings back to DateTimes', () {
      final habit = mapper.toEntity(row(completionLog: const ['2026-03-01', '2026-03-02']));
      expect(habit.completionLog, [DateTime(2026, 3, 1), DateTime(2026, 3, 2)]);
    });

    test('leaves lastCompletedAt null when the column is null', () {
      final habit = mapper.toEntity(row());
      expect(habit.lastCompletedAt, isNull);
    });
  });

  group('HabitMapper round-trip', () {
    test('Habit -> HabitRow -> Habit preserves all domain fields', () {
      final original = habit(
        id: 'habit-rt',
        name: 'Round Trip',
        status: HabitStatus.active,
        frequency: HabitFrequency.weekly,
        description: 'Some details',
        currentStreak: 4,
        longestStreak: 7,
        completionLog: [DateTime(2026, 5, 1), DateTime(2026, 5, 8)],
        lastCompletedAt: DateTime(2026, 5, 8),
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.name, original.name);
      expect(restored.status, original.status);
      expect(restored.frequency, original.frequency);
      expect(restored.description, original.description);
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.longestStreak, original.longestStreak);
      expect(restored.completionLog, original.completionLog);
      expect(restored.lastCompletedAt, original.lastCompletedAt);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trips an archived habit', () {
      final original = habit(status: HabitStatus.archived);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.status, HabitStatus.archived);
    });
  });
}
