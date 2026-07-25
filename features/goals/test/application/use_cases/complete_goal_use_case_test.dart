import 'package:feature_goals/src/application/use_cases/complete_goal_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

Goal _existing({
  GoalStatus status = GoalStatus.active,
  double targetValue = 10,
  double currentProgress = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return Goal(
    id: const GoalId('goal-1'),
    workspaceId: _ws,
    name: 'Goal',
    targetValue: targetValue,
    status: status,
    currentProgress: currentProgress,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CompleteGoalUseCase', () {
    test('records progress against an active goal', () async {
      final repo = FakeGoalRepository()..seed([_existing()]);
      final useCase = CompleteGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const CompleteGoalInput(
          goalId: GoalId('goal-1'),
          workspaceId: _ws,
          progressDelta: 3,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.currentProgress, 3);
    });

    test('accumulates progress across multiple calls', () async {
      final repo = FakeGoalRepository()..seed([_existing(currentProgress: 2)]);
      final useCase = CompleteGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const CompleteGoalInput(
          goalId: GoalId('goal-1'),
          workspaceId: _ws,
          progressDelta: 4,
        ),
      );

      expect(result.valueOrNull!.currentProgress, 6);
    });

    test('rejects recording progress for an archived goal', () async {
      final repo = FakeGoalRepository()
        ..seed([_existing(status: GoalStatus.archived)]);
      final useCase = CompleteGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const CompleteGoalInput(
          goalId: GoalId('goal-1'),
          workspaceId: _ws,
          progressDelta: 1,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });

    test('rejects a delta that would drive progress negative', () async {
      final repo = FakeGoalRepository()..seed([_existing(currentProgress: 1)]);
      final useCase = CompleteGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const CompleteGoalInput(
          goalId: GoalId('goal-1'),
          workspaceId: _ws,
          progressDelta: -5,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });

    test('fails when the goal does not exist', () async {
      final repo = FakeGoalRepository();
      final useCase = CompleteGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const CompleteGoalInput(
          goalId: GoalId('missing'),
          workspaceId: _ws,
          progressDelta: 1,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });
  });
}
