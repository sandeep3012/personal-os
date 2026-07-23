import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

Goal _goal({
  GoalStatus status = GoalStatus.active,
  String name = 'Run a marathon',
  double targetValue = 10,
  double currentProgress = 0,
  String? unit,
}) {
  final now = DateTime(2026, 1, 1);
  return Goal(
    id: const GoalId('goal-1'),
    workspaceId: _ws,
    name: name,
    targetValue: targetValue,
    currentProgress: currentProgress,
    unit: unit,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Goal construction', () {
    test('throws when name is empty', () {
      expect(() => _goal(name: ''), throwsA(isA<GoalsException>()));
    });

    test('throws when name is only whitespace', () {
      expect(() => _goal(name: '   '), throwsA(isA<GoalsException>()));
    });

    test('throws when name exceeds 200 characters', () {
      expect(() => _goal(name: 'a' * 201), throwsA(isA<GoalsException>()));
    });

    test('accepts a name at exactly 200 characters', () {
      expect(() => _goal(name: 'a' * 200), returnsNormally);
    });

    test('throws when targetValue is zero', () {
      expect(() => _goal(targetValue: 0), throwsA(isA<GoalsException>()));
    });

    test('throws when targetValue is negative', () {
      expect(() => _goal(targetValue: -5), throwsA(isA<GoalsException>()));
    });

    test('throws when currentProgress is negative', () {
      expect(
        () => _goal(currentProgress: -1),
        throwsA(isA<GoalsException>()),
      );
    });

    test('defaults to zero progress', () {
      final goal = _goal();
      expect(goal.currentProgress, 0);
    });
  });

  group('Goal.progressRatio', () {
    test('is 0 with no progress', () {
      expect(_goal(targetValue: 10, currentProgress: 0).progressRatio, 0);
    });

    test('is 0.5 at half progress', () {
      expect(_goal(targetValue: 10, currentProgress: 5).progressRatio, 0.5);
    });

    test('clamps to 1 when progress exceeds target', () {
      expect(_goal(targetValue: 10, currentProgress: 20).progressRatio, 1);
    });
  });

  group('Goal.transitionTo', () {
    test('active -> completed succeeds', () {
      final goal = _goal();
      final result =
          goal.transitionTo(GoalStatus.completed, now: DateTime(2026, 1, 2));
      expect(result.status, GoalStatus.completed);
    });

    test('active -> archived succeeds', () {
      final goal = _goal();
      final result =
          goal.transitionTo(GoalStatus.archived, now: DateTime(2026, 1, 2));
      expect(result.status, GoalStatus.archived);
    });

    test('completed -> archived succeeds', () {
      final goal = _goal(status: GoalStatus.completed);
      final result =
          goal.transitionTo(GoalStatus.archived, now: DateTime(2026, 1, 2));
      expect(result.status, GoalStatus.archived);
    });

    test('archived cannot transition anywhere (terminal)', () {
      final goal = _goal(status: GoalStatus.archived);
      expect(
        () => goal.transitionTo(GoalStatus.active, now: DateTime(2026, 1, 2)),
        throwsA(isA<GoalsException>()),
      );
    });

    test('completed cannot transition back to active', () {
      final goal = _goal(status: GoalStatus.completed);
      expect(
        () => goal.transitionTo(GoalStatus.active, now: DateTime(2026, 1, 2)),
        throwsA(isA<GoalsException>()),
      );
    });

    test('preserves progress state across a transition', () {
      final goal = _goal(currentProgress: 3);
      final archived =
          goal.transitionTo(GoalStatus.archived, now: DateTime(2026, 1, 2));
      expect(archived.currentProgress, 3);
    });
  });

  group('Goal.recordProgress', () {
    test('adds delta to currentProgress', () {
      final goal = _goal(targetValue: 10, currentProgress: 2);
      final result = goal.recordProgress(3, now: DateTime(2026, 1, 2));
      expect(result.currentProgress, 5);
    });

    test('does not auto-complete when target is reached', () {
      final goal = _goal(targetValue: 10, currentProgress: 9);
      final result = goal.recordProgress(1, now: DateTime(2026, 1, 2));
      expect(result.currentProgress, 10);
      expect(result.status, GoalStatus.active);
    });

    test('throws when delta would drive progress negative', () {
      final goal = _goal(currentProgress: 1);
      expect(
        () => goal.recordProgress(-5, now: DateTime(2026, 1, 2)),
        throwsA(isA<GoalsException>()),
      );
    });

    test('throws when the goal is not active', () {
      final goal = _goal(status: GoalStatus.archived);
      expect(
        () => goal.recordProgress(1, now: DateTime(2026, 1, 2)),
        throwsA(isA<GoalsException>()),
      );
    });
  });

  group('Goal.copyWith', () {
    test('does not change status or progress', () {
      final goal = _goal(currentProgress: 3);
      final updated = goal.copyWith(name: 'Renamed');
      expect(updated.status, GoalStatus.active);
      expect(updated.name, 'Renamed');
      expect(updated.currentProgress, 3);
    });

    test('updates targetValue when supplied', () {
      final goal = _goal(targetValue: 10);
      final updated = goal.copyWith(targetValue: 20);
      expect(updated.targetValue, 20);
    });
  });

  group('Goal equality', () {
    test('two goals with the same id are equal regardless of other fields', () {
      final now = DateTime(2026, 1, 1);
      final a = Goal(
        id: const GoalId('goal-1'),
        workspaceId: _ws,
        name: 'A',
        targetValue: 10,
        status: GoalStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final b = Goal(
        id: const GoalId('goal-1'),
        workspaceId: _ws,
        name: 'B',
        targetValue: 20,
        status: GoalStatus.completed,
        createdAt: now,
        updatedAt: now,
      );
      expect(a, b);
    });
  });
}
