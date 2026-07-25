import 'package:application/application.dart';
import 'package:feature_goals/src/application/use_cases/archive_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/complete_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/create_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/delete_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/get_goals_use_case.dart';
import 'package:feature_goals/src/application/use_cases/update_goal_use_case.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:feature_goals/src/presentation/viewmodels/goals_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'goal-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeGoalRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = GoalsViewModel(
      getGoalsUseCase: GetGoalsUseCase(goalRepository: repo),
      createGoalUseCase: CreateGoalUseCase(
        goalRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateGoalUseCase: UpdateGoalUseCase(goalRepository: repo),
      completeGoalUseCase: CompleteGoalUseCase(goalRepository: repo),
      archiveGoalUseCase: ArchiveGoalUseCase(goalRepository: repo),
      deleteGoalUseCase: DeleteGoalUseCase(goalRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeGoalRepository repo;
  late final WorkspaceContext workspaceContext;
  late final GoalsViewModel viewModel;
}

void main() {
  group('GoalsViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('shows an empty list when no goals exist', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      // Should not throw — the ViewModel unsubscribed from WorkspaceContext
      // in dispose(), so this switch must not touch a disposed ChangeNotifier.
      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });

  group('GoalsViewModel.createGoal', () {
    test('creates a goal starting active with zero progress and reloads the list',
        () async {
      final harness = _Harness();
      await harness.viewModel.load();

      final result = await harness.viewModel.createGoal(
        name: 'Buy milk',
        targetValue: 10,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, GoalStatus.active);
      expect(result.valueOrNull!.currentProgress, 0);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('GoalsViewModel.updateGoal', () {
    test('updates the name and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createGoal(
        name: 'Original',
        targetValue: 10,
      );

      final result = await harness.viewModel.updateGoal(
        goalId: created.valueOrNull!.id,
        name: 'Renamed',
      );

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull!.single.name, 'Renamed');
    });
  });

  group('GoalsViewModel.completeGoal', () {
    test('records progress and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createGoal(
        name: 'Goal',
        targetValue: 10,
      );

      final result =
          await harness.viewModel.completeGoal(created.valueOrNull!.id, 3);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.currentProgress, 3);
    });

    test('fails when the goal is archived', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createGoal(
        name: 'Goal',
        targetValue: 10,
      );
      await harness.viewModel.archiveGoal(created.valueOrNull!.id);

      final result =
          await harness.viewModel.completeGoal(created.valueOrNull!.id, 1);

      expect(result.isFailure, isTrue);
    });
  });

  group('GoalsViewModel.archiveGoal', () {
    test('archives a goal and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createGoal(
        name: 'Goal',
        targetValue: 10,
      );

      final result = await harness.viewModel.archiveGoal(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, GoalStatus.archived);
    });
  });

  group('GoalsViewModel.deleteGoal', () {
    test('soft-deletes a goal and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createGoal(
        name: 'Goal',
        targetValue: 10,
      );
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      final result = await harness.viewModel.deleteGoal(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });
}
