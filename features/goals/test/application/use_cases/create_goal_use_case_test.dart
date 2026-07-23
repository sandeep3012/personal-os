import 'package:feature_goals/src/application/use_cases/create_goal_use_case.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../../helpers/fake_goal_repository.dart';

final class _FixedIdGenerator implements IdGenerator {
  int _i = 0;
  @override
  String generate() => 'goal-${++_i}';
}

void main() {
  late FakeGoalRepository repo;
  late CreateGoalUseCase useCase;

  setUp(() {
    repo = FakeGoalRepository();
    useCase = CreateGoalUseCase(
      goalRepository: repo,
      idGenerator: _FixedIdGenerator(),
    );
  });

  group('CreateGoalUseCase', () {
    test('creates and persists a goal starting active with zero progress',
        () async {
      final result = await useCase.execute(
        const CreateGoalInput(
          workspaceId: 'ws-1',
          name: 'Run a marathon',
          targetValue: 42,
        ),
      );

      expect(result.isSuccess, isTrue);
      final goal = result.valueOrNull!;
      expect(goal.name, 'Run a marathon');
      expect(goal.status, GoalStatus.active);
      expect(goal.currentProgress, 0);
      expect(repo.store, contains(goal));
    });

    test('returns generated id for the new goal', () async {
      final result = await useCase.execute(
        const CreateGoalInput(
          workspaceId: 'ws-1',
          name: 'Goal',
          targetValue: 10,
        ),
      );

      expect(result.valueOrNull!.id.value, 'goal-1');
    });

    test('accepts an optional description, unit, and target date', () async {
      final result = await useCase.execute(
        const CreateGoalInput(
          workspaceId: 'ws-1',
          name: 'Goal',
          targetValue: 5000,
          unit: 'USD',
          description: 'Details',
        ),
      );

      expect(result.valueOrNull!.description, 'Details');
      expect(result.valueOrNull!.unit, 'USD');
    });

    test('rejects a description longer than 1000 characters', () async {
      final result = await useCase.execute(
        CreateGoalInput(
          workspaceId: 'ws-1',
          name: 'Goal',
          targetValue: 10,
          description: 'a' * 1001,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });

    test('rejects an empty name (entity invariant)', () async {
      final result = await useCase.execute(
        const CreateGoalInput(
          workspaceId: 'ws-1',
          name: '',
          targetValue: 10,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });

    test('rejects a non-positive target value (entity invariant)', () async {
      final result = await useCase.execute(
        const CreateGoalInput(
          workspaceId: 'ws-1',
          name: 'Goal',
          targetValue: 0,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });
  });
}
