import 'package:feature_goals/src/data/mappers/goal_mapper.dart';
import 'package:feature_goals/src/data/models/goal_row.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:feature_goals/src/domain/value_objects/goal_target_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = GoalMapper();

  Goal goal({
    String id = 'goal-1',
    String name = 'Run a marathon',
    double targetValue = 42,
    double currentProgress = 0,
    GoalStatus status = GoalStatus.active,
    String? description,
    String? unit,
    GoalTargetDate? targetDate,
  }) {
    final now = DateTime(2024, 1, 1, 10, 30);
    return Goal(
      id: GoalId(id),
      workspaceId: 'ws-1',
      name: name,
      targetValue: targetValue,
      currentProgress: currentProgress,
      status: status,
      description: description,
      unit: unit,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: DateTime(2024, 2, 1, 8),
    );
  }

  group('GoalMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(goal(id: 'goal-1', name: 'Run a marathon'));

      expect(row.goalId, 'goal-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.name, 'Run a marathon');
      expect(row.status, 'active');
      expect(row.targetValue, 42);
    });

    test('maps every GoalStatus to its enum name', () {
      for (final status in GoalStatus.values) {
        final row = mapper.toRow(goal(status: status));
        expect(row.status, status.name);
      }
    });

    test('maps unit and targetDate when present', () {
      final row = mapper.toRow(
        goal(unit: 'km', targetDate: GoalTargetDate(DateTime(2026, 6, 1))),
      );
      expect(row.unit, 'km');
      expect(row.targetDate, DateTime(2026, 6, 1));
    });

    test('always maps deletedAt to null (domain Goal is never soft-deleted)',
        () {
      final row = mapper.toRow(goal());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode names', () {
      final row = mapper.toRow(goal(name: 'Café run ☕ 買い物'));
      expect(row.name, 'Café run ☕ 買い物');
    });
  });

  group('GoalMapper.toEntity', () {
    GoalRow row({
      String id = 'goal-1',
      String name = 'Run a marathon',
      String status = 'active',
      double targetValue = 42,
      double currentProgress = 0,
      String? unit,
      DateTime? targetDate,
    }) {
      final now = DateTime(2024, 1, 1, 10, 30);
      return GoalRow(
        goalId: id,
        workspaceId: 'ws-1',
        name: name,
        targetValue: targetValue,
        currentProgress: currentProgress,
        status: status,
        unit: unit,
        targetDate: targetDate,
        createdAt: now,
        updatedAt: DateTime(2024, 2, 1, 8),
      );
    }

    test('maps all scalar fields', () {
      final goal = mapper.toEntity(row(id: 'goal-2', name: 'Meditate'));

      expect(goal.id, const GoalId('goal-2'));
      expect(goal.workspaceId, 'ws-1');
      expect(goal.name, 'Meditate');
    });

    test('converts every status column value back to its enum', () {
      for (final status in GoalStatus.values) {
        final goal = mapper.toEntity(row(status: status.name));
        expect(goal.status, status);
      }
    });

    test('throws GoalsException for an unrecognized status value', () {
      expect(
        () => mapper.toEntity(row(status: 'not_a_real_status')),
        throwsA(isA<GoalsException>()),
      );
    });

    test('converts targetDate back to a GoalTargetDate', () {
      final goal = mapper.toEntity(row(targetDate: DateTime(2026, 6, 1)));
      expect(goal.targetDate, GoalTargetDate(DateTime(2026, 6, 1)));
    });

    test('leaves targetDate null when the column is null', () {
      final goal = mapper.toEntity(row());
      expect(goal.targetDate, isNull);
    });
  });

  group('GoalMapper round-trip', () {
    test('Goal -> GoalRow -> Goal preserves all domain fields', () {
      final original = goal(
        id: 'goal-rt',
        name: 'Round Trip',
        status: GoalStatus.active,
        targetValue: 100,
        currentProgress: 40,
        description: 'Some details',
        unit: 'km',
        targetDate: GoalTargetDate(DateTime(2026, 5, 8)),
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.name, original.name);
      expect(restored.status, original.status);
      expect(restored.targetValue, original.targetValue);
      expect(restored.currentProgress, original.currentProgress);
      expect(restored.description, original.description);
      expect(restored.unit, original.unit);
      expect(restored.targetDate, original.targetDate);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trips an archived goal', () {
      final original = goal(status: GoalStatus.archived);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.status, GoalStatus.archived);
    });
  });
}
