import 'package:feature_goals/src/application/use_cases/delete_goal_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

void main() {
  group('DeleteGoalUseCase', () {
    test('soft-deletes an existing goal', () async {
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
      final useCase = DeleteGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const DeleteGoalInput(goalId: GoalId('goal-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.store, isEmpty);
    });

    test('is idempotent — deleting a nonexistent goal still succeeds',
        () async {
      final repo = FakeGoalRepository();
      final useCase = DeleteGoalUseCase(goalRepository: repo);

      final result = await useCase.execute(
        const DeleteGoalInput(goalId: GoalId('missing'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
