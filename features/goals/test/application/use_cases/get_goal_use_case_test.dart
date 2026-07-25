import 'package:feature_goals/src/application/use_cases/get_goal_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

void main() {
  group('GetGoalUseCase', () {
    test('returns the goal when it exists', () async {
      final now = DateTime(2026, 1, 1);
      final goal = Goal(
        id: const GoalId('goal-1'),
        workspaceId: _ws,
        name: 'Goal',
    targetValue: 10,
        status: GoalStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final repo = FakeGoalRepository()..seed([goal]);
      final useCase = GetGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const GetGoalInput(goalId: GoalId('goal-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'Goal');
    });

    test('fails when the goal does not exist', () async {
      final repo = FakeGoalRepository();
      final useCase = GetGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const GetGoalInput(goalId: GoalId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });
  });
}
