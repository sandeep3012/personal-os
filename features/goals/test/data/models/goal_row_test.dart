import 'package:feature_goals/src/data/models/goal_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalRow toMap/fromMap round-trip', () {
    test('round-trips all fields including nullable ones', () {
      final row = GoalRow(
        goalId: 'goal-1',
        workspaceId: 'ws-1',
        name: 'Run a marathon',
        targetValue: 42,
        currentProgress: 10,
        status: 'active',
        description: 'Train for it',
        unit: 'km',
        targetDate: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 3, 8),
        deletedAt: null,
      );

      final restored = GoalRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips a fully nullable-fields-populated row', () {
      final row = GoalRow(
        goalId: 'goal-2',
        workspaceId: 'ws-1',
        name: 'Archived goal',
        targetValue: 5,
        currentProgress: 2,
        status: 'archived',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 6),
        deletedAt: DateTime(2026, 1, 7),
      );

      final restored = GoalRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips minimal fields (no description/unit/targetDate)', () {
      final row = GoalRow(
        goalId: 'goal-3',
        workspaceId: 'ws-1',
        name: 'Minimal',
        targetValue: 1,
        currentProgress: 0,
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = GoalRow.fromMap(row.toMap());

      expect(restored, row);
      expect(restored.description, isNull);
      expect(restored.unit, isNull);
      expect(restored.targetDate, isNull);
      expect(restored.deletedAt, isNull);
    });
  });
}
