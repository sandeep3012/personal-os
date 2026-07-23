import 'package:feature_goals/src/application/use_cases/get_goals_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

Goal _goal(String id, GoalStatus status) {
  final now = DateTime(2026, 1, 1);
  return Goal(
    id: GoalId(id),
    workspaceId: _ws,
    name: 'Goal $id',
    targetValue: 10,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GetGoalsUseCase', () {
    test('returns an empty list when no goals exist', () async {
      final repo = FakeGoalRepository();
      final useCase = GetGoalsUseCase(goalRepository: repo);

      final result = await useCase.execute(const GetGoalsInput(workspaceId: _ws));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all goals regardless of status, including archived',
        () async {
      final repo = FakeGoalRepository()
        ..seed([
          _goal('t1', GoalStatus.active),
          _goal('t2', GoalStatus.active),
          _goal('t3', GoalStatus.archived),
        ]);
      final useCase = GetGoalsUseCase(goalRepository: repo);

      final result = await useCase.execute(const GetGoalsInput(workspaceId: _ws));

      expect(result.valueOrNull, hasLength(3));
    });
  });
}
