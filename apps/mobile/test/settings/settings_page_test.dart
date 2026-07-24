import 'package:feature_finance/finance.dart';
import 'package:feature_goals/goals.dart';
import 'package:feature_habits/habits.dart';
import 'package:feature_notes/notes.dart';
import 'package:feature_tasks/tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/app/demo/demo_mode_controller.dart';
import 'package:personal_os/app/demo/switchable_finance_storage.dart';
import 'package:personal_os/app/demo/switchable_goal_storage.dart';
import 'package:personal_os/app/demo/switchable_habit_storage.dart';
import 'package:personal_os/app/demo/switchable_note_storage.dart';
import 'package:personal_os/app/demo/switchable_task_storage.dart';
import 'package:personal_os/app/settings/settings_page.dart';

const _ws = 'ws-settings-test';

DemoModeController _controller() {
  final realExecutor = InMemoryFinanceDatabaseExecutor();
  final realRunner = InMemoryFinanceTransactionRunner(realExecutor);
  final realTaskExecutor = InMemoryTaskDatabaseExecutor();
  final realTaskRunner = InMemoryTaskTransactionRunner(realTaskExecutor);
  final realHabitExecutor = InMemoryHabitDatabaseExecutor();
  final realHabitRunner = InMemoryHabitTransactionRunner(realHabitExecutor);
  final realGoalExecutor = InMemoryGoalDatabaseExecutor();
  final realGoalRunner = InMemoryGoalTransactionRunner(realGoalExecutor);
  final realNoteExecutor = InMemoryNoteDatabaseExecutor();
  final realNoteRunner = InMemoryNoteTransactionRunner(realNoteExecutor);
  return DemoModeController(
    financeExecutor: SwitchableFinanceDatabaseExecutor(realExecutor),
    financeRunner: SwitchableFinanceTransactionRunner(realRunner),
    realFinanceExecutor: realExecutor,
    realFinanceRunner: realRunner,
    taskExecutor: SwitchableTaskDatabaseExecutor(realTaskExecutor),
    taskRunner: SwitchableTaskTransactionRunner(realTaskRunner),
    realTaskExecutor: realTaskExecutor,
    realTaskRunner: realTaskRunner,
    habitExecutor: SwitchableHabitDatabaseExecutor(realHabitExecutor),
    habitRunner: SwitchableHabitTransactionRunner(realHabitRunner),
    realHabitExecutor: realHabitExecutor,
    realHabitRunner: realHabitRunner,
    goalExecutor: SwitchableGoalDatabaseExecutor(realGoalExecutor),
    goalRunner: SwitchableGoalTransactionRunner(realGoalRunner),
    realGoalExecutor: realGoalExecutor,
    realGoalRunner: realGoalRunner,
    noteExecutor: SwitchableNoteDatabaseExecutor(realNoteExecutor),
    noteRunner: SwitchableNoteTransactionRunner(realNoteRunner),
    realNoteExecutor: realNoteExecutor,
    realNoteRunner: realNoteRunner,
    workspaceId: _ws,
  );
}

Widget _buildPage(DemoModeController controller) =>
    MaterialApp(home: SettingsPage(demoModeController: controller));

void main() {
  group('SettingsPage — Demo Mode management', () {
    testWidgets('shows "Off" and an Enable option when not in Demo Mode',
        (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_buildPage(controller));

      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Enable Demo Mode'), findsOneWidget);
      expect(find.text('Exit Demo Mode'), findsNothing);
      expect(find.text('Reset Demo Data'), findsNothing);
    });

    testWidgets('tapping Enable Demo Mode turns Demo Mode on', (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_buildPage(controller));

      await tester.tap(find.text('Enable Demo Mode'));
      await tester.pumpAndSettle();

      expect(controller.isDemoMode, isTrue);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Exit Demo Mode'), findsOneWidget);
      expect(find.text('Reset Demo Data'), findsOneWidget);
    });

    testWidgets('tapping Exit Demo Mode turns Demo Mode off', (tester) async {
      final controller = _controller();
      await controller.enableDemoMode();
      await tester.pumpWidget(_buildPage(controller));

      await tester.tap(find.text('Exit Demo Mode'));
      await tester.pumpAndSettle();

      expect(controller.isDemoMode, isFalse);
      expect(find.text('Enable Demo Mode'), findsOneWidget);
    });

    testWidgets(
        'Reset Demo Data shows a confirmation dialog and only resets on '
        'confirm', (tester) async {
      final controller = _controller();
      await controller.enableDemoMode();
      await tester.pumpWidget(_buildPage(controller));
      final generationBefore = controller.generation;

      await tester.tap(find.text('Reset Demo Data'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Demo Data'), findsWidgets); // dialog title + tile
      expect(find.textContaining('the current demo data'), findsOneWidget);

      // Cancelling must not reset.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.generation, generationBefore);

      await tester.tap(find.text('Reset Demo Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pumpAndSettle();

      expect(controller.generation, greaterThan(generationBefore));
      expect(controller.isDemoMode, isTrue);
    });
  });
}
