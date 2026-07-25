import 'package:feature_habits/src/data/models/habit_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitRow toMap/fromMap round-trip', () {
    test('round-trips all fields including nullable ones', () {
      final row = HabitRow(
        habitId: 'habit-1',
        workspaceId: 'ws-1',
        name: 'Drink water',
        frequency: 'daily',
        status: 'active',
        description: 'Eight glasses a day',
        currentStreak: 3,
        longestStreak: 5,
        completionLog: const ['2026-01-01', '2026-01-02', '2026-01-03'],
        lastCompletedAt: DateTime(2026, 1, 3),
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 3, 8),
        deletedAt: null,
      );

      final restored = HabitRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips a fully nullable-fields-populated row', () {
      final row = HabitRow(
        habitId: 'habit-2',
        workspaceId: 'ws-1',
        name: 'Archived habit',
        frequency: 'weekly',
        status: 'archived',
        currentStreak: 0,
        longestStreak: 2,
        completionLog: const [],
        lastCompletedAt: DateTime(2026, 1, 5),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 6),
        deletedAt: DateTime(2026, 1, 7),
      );

      final restored = HabitRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips minimal fields (no description/lastCompletedAt)', () {
      final row = HabitRow(
        habitId: 'habit-3',
        workspaceId: 'ws-1',
        name: 'Minimal',
        frequency: 'daily',
        status: 'active',
        currentStreak: 0,
        longestStreak: 0,
        completionLog: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = HabitRow.fromMap(row.toMap());

      expect(restored, row);
      expect(restored.description, isNull);
      expect(restored.lastCompletedAt, isNull);
      expect(restored.deletedAt, isNull);
      expect(restored.completionLog, isEmpty);
    });
  });
}
