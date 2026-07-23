import 'package:application/application.dart';
import 'package:feature_goals/src/application/use_cases/get_goals_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:feature_goals/src/presentation/viewmodels/goals_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

Goal _goal(String id, {GoalStatus status = GoalStatus.active}) {
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

final class _Harness {
  _Harness() : repo = FakeGoalRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = GoalsHomeViewModel(
      getGoalsUseCase: GetGoalsUseCase(goalRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeGoalRepository repo;
  late final WorkspaceContext workspaceContext;
  late final GoalsHomeViewModel viewModel;
}

void main() {
  group('GoalsHomeViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('activeCount counts only active goals', () async {
      final harness = _Harness()
        ..repo.seed([
          _goal('t1', status: GoalStatus.active),
          _goal('t2', status: GoalStatus.active),
          _goal('t3', status: GoalStatus.archived),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.activeCount, 2);
    });

    test('completedCount counts only completed goals', () async {
      final harness = _Harness()
        ..repo.seed([
          _goal('t1', status: GoalStatus.completed),
          _goal('t2', status: GoalStatus.completed),
          _goal('t3', status: GoalStatus.active),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.completedCount, 2);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });
}
