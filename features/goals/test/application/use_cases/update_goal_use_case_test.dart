import 'package:feature_goals/src/application/use_cases/update_goal_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

Goal _existing({GoalStatus status = GoalStatus.active}) {
  final now = DateTime(2026, 1, 1);
  return Goal(
    id: const GoalId('goal-1'),
    workspaceId: _ws,
    name: 'Original title',
    targetValue: 10,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeGoalRepository repo;
  late UpdateGoalUseCase useCase;

  setUp(() {
    repo = FakeGoalRepository()..seed([_existing()]);
    useCase = UpdateGoalUseCase(goalRepository: repo);
  });

  group('UpdateGoalUseCase', () {
    test('updates the name', () async {
      final result = await useCase.execute(
        const UpdateGoalInput(
          goalId: GoalId('goal-1'),
          workspaceId: _ws,
          name: 'Renamed',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'Renamed');
    });

    test('does not change status', () async {
      final result = await useCase.execute(
        const UpdateGoalInput(
          goalId: GoalId('goal-1'),
          workspaceId: _ws,
          name: 'Renamed',
        ),
      );

      expect(result.valueOrNull!.status, GoalStatus.active);
    });

    test('rejects a description longer than 1000 characters', () async {
      final result = await useCase.execute(
        UpdateGoalInput(
          goalId: const GoalId('goal-1'),
          workspaceId: _ws,
          description: 'a' * 1001,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });

    test('fails when the goal does not exist', () async {
      final result = await useCase.execute(
        const UpdateGoalInput(
          goalId: GoalId('missing'),
          workspaceId: _ws,
          name: 'X',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });
  });
}
