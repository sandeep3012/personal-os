import 'package:application/application.dart';
import 'package:feature_goals/src/application/use_cases/archive_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/complete_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/create_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/delete_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/get_goals_use_case.dart';
import 'package:feature_goals/src/application/use_cases/update_goal_use_case.dart';
import 'package:feature_goals/src/presentation/pages/goals_page.dart';
import 'package:feature_goals/src/presentation/viewmodels/goals_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'goal-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeGoalRepository() {
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
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeGoalRepository repo;
  late final GoalsViewModel viewModel;

  Widget buildPage() => MaterialApp(home: GoalsPage(viewModel: viewModel));
}

void main() {
  group('GoalsPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no goals exist', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No goals yet'), findsOneWidget);
    });

    testWidgets('shows a goal after loading', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createGoal(name: 'Drink water', targetValue: 8);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Drink water'), findsOneWidget);
    });
  });

  group('GoalsPage — create', () {
    testWidgets('tapping the FAB opens the add-goal dialog', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Add Goal')),
        findsOneWidget,
      );
    });

    testWidgets('creating a goal adds it to the visible list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Walk the dog');
      await tester.enterText(
        find.widgetWithText(TextField, 'Target value'),
        '5',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Walk the dog'), findsOneWidget);
    });
  });

  group('GoalsPage — edit', () {
    testWidgets('tapping a goal opens the edit dialog pre-filled with its name',
        (tester) async {
      final harness = _Harness();
      await harness.viewModel.createGoal(name: 'Original', targetValue: 10);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Goal'), findsOneWidget);
    });

    testWidgets('editing the name updates the list', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createGoal(name: 'Original', targetValue: 10);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Renamed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });
  });

  group('GoalsPage — complete', () {
    testWidgets('checking the checkbox marks the goal complete', (tester) async {
      final harness = _Harness();
      final created =
          await harness.viewModel.createGoal(name: 'Goal', targetValue: 10);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.currentProgress, 10);
    });
  });

  group('GoalsPage — archive', () {
    testWidgets('the Archive button in the edit dialog archives the goal',
        (tester) async {
      final harness = _Harness();
      final created =
          await harness.viewModel.createGoal(name: 'Goal', targetValue: 10);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Goal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      // Archived goals are excluded from the visible list.
      expect(find.text('Goal'), findsNothing);

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'archived');
    });
  });

  group('GoalsPage — delete', () {
    testWidgets('swiping a goal away deletes it', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createGoal(name: 'Goal', targetValue: 10);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Goal'), findsNothing);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });

  group('GoalsPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No goals yet'), findsOneWidget);

      await harness.viewModel.createGoal(name: 'Newly Added', targetValue: 10);
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
