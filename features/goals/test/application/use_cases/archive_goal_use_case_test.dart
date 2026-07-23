import 'package:feature_goals/src/application/use_cases/archive_goal_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

Goal _existing(GoalStatus status, {double currentProgress = 0}) {
  final now = DateTime(2026, 1, 1);
  return Goal(
    id: const GoalId('goal-1'),
    workspaceId: _ws,
    name: 'Goal',
    targetValue: 10,
    status: status,
    currentProgress: currentProgress,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ArchiveGoalUseCase', () {
    test('archives an active goal', () async {
      final repo = FakeGoalRepository()..seed([_existing(GoalStatus.active)]);
      final useCase = ArchiveGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const ArchiveGoalInput(goalId: GoalId('goal-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, GoalStatus.archived);
    });

    test('archiving a completed goal retains progress', () async {
      final repo = FakeGoalRepository()
        ..seed([_existing(GoalStatus.completed, currentProgress: 10)]);
      final useCase = ArchiveGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const ArchiveGoalInput(goalId: GoalId('goal-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.currentProgress, 10);
    });

    test('rejects archiving an already-archived goal', () async {
      final repo = FakeGoalRepository()
        ..seed([_existing(GoalStatus.archived)]);
      final useCase = ArchiveGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const ArchiveGoalInput(goalId: GoalId('goal-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });

    test('fails when the goal does not exist', () async {
      final repo = FakeGoalRepository();
      final useCase = ArchiveGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const ArchiveGoalInput(goalId: GoalId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
