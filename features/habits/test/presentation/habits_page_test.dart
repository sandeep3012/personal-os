import 'package:application/application.dart';
import 'package:feature_habits/src/application/use_cases/archive_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/complete_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/create_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/delete_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/get_habits_use_case.dart';
import 'package:feature_habits/src/application/use_cases/update_habit_use_case.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/presentation/pages/habits_page.dart';
import 'package:feature_habits/src/presentation/viewmodels/habits_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'habit-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeHabitRepository() {
    viewModel = HabitsViewModel(
      getHabitsUseCase: GetHabitsUseCase(habitRepository: repo),
      createHabitUseCase: CreateHabitUseCase(
        habitRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateHabitUseCase: UpdateHabitUseCase(habitRepository: repo),
      completeHabitUseCase: CompleteHabitUseCase(habitRepository: repo),
      archiveHabitUseCase: ArchiveHabitUseCase(habitRepository: repo),
      deleteHabitUseCase: DeleteHabitUseCase(habitRepository: repo),
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeHabitRepository repo;
  late final HabitsViewModel viewModel;

  Widget buildPage() => MaterialApp(home: HabitsPage(viewModel: viewModel));
}

void main() {
  group('HabitsPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no habits exist', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No habits yet'), findsOneWidget);
    });

    testWidgets('shows a habit after loading', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createHabit(
        name: 'Drink water',
        frequency: HabitFrequency.daily,
      );
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Drink water'), findsOneWidget);
    });
  });

  group('HabitsPage — create', () {
    testWidgets('tapping the FAB opens the add-habit dialog', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Add Habit')),
        findsOneWidget,
      );
    });

    testWidgets('creating a habit adds it to the visible list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Walk the dog');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Walk the dog'), findsOneWidget);
    });
  });

  group('HabitsPage — edit', () {
    testWidgets('tapping a habit opens the edit dialog pre-filled with its name',
        (tester) async {
      final harness = _Harness();
      await harness.viewModel.createHabit(name: 'Original', frequency: HabitFrequency.daily);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Habit'), findsOneWidget);
    });

    testWidgets('editing the name updates the list', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createHabit(name: 'Original', frequency: HabitFrequency.daily);
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

  group('HabitsPage — complete', () {
    testWidgets('checking the checkbox logs a completion', (tester) async {
      final harness = _Harness();
      final created =
          await harness.viewModel.createHabit(name: 'Habit', frequency: HabitFrequency.daily);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.currentStreak, 1);
    });
  });

  group('HabitsPage — archive', () {
    testWidgets('the Archive button in the edit dialog archives the habit',
        (tester) async {
      final harness = _Harness();
      final created =
          await harness.viewModel.createHabit(name: 'Habit', frequency: HabitFrequency.daily);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Habit'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      // Archived habits are excluded from the visible list.
      expect(find.text('Habit'), findsNothing);

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'archived');
    });
  });

  group('HabitsPage — delete', () {
    testWidgets('swiping a habit away deletes it', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createHabit(name: 'Habit', frequency: HabitFrequency.daily);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Habit'), findsNothing);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });

  group('HabitsPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No habits yet'), findsOneWidget);

      await harness.viewModel.createHabit(name: 'Newly Added', frequency: HabitFrequency.daily);
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
