import 'dart:io';

import 'package:feature_finance/finance.dart';
import 'package:feature_goals/goals.dart';
import 'package:feature_habits/habits.dart';
import 'package:feature_notes/notes.dart';
import 'package:feature_tasks/tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/app/bootstrap/app_bootstrap.dart';
import 'package:personal_os/app/home/home_dashboard_page.dart';

/// Mirrors app_bootstrap_test.dart's pattern: a real [AppBootstrap.boot]
/// against a private temp file, since [FinanceHomeViewModel] is only
/// buildable through DI (its use-case dependencies aren't part of
/// feature_finance's public barrel — mirroring how every other Finance
/// widget test in this repo either uses feature-internal fakes or, for
/// app-layer tests like this one, boots the real DI graph).
///
/// [AppBootstrap.boot] does real file I/O (the file-backed Finance
/// executor), and `testWidgets`' default zone only fakes/drives `Timer`s
/// tied to frame pumping — genuine async I/O needs [WidgetTester.runAsync]
/// to actually resolve, otherwise the awaited `Future` never completes and
/// the test hangs. Every test below therefore wraps its whole body (boot +
/// pump) in one `runAsync` call, the standard idiom for combining real I/O
/// with widget pumping.
File _tempFinanceFile() => File(
      '${Directory.systemTemp.createTempSync('home_dashboard_test_').path}'
      '/finance_data.json',
    );

File _tempTasksFile() => File(
      '${Directory.systemTemp.createTempSync('home_dashboard_tasks_test_').path}'
      '/tasks_data.json',
    );

File _tempHabitsFile() => File(
      '${Directory.systemTemp.createTempSync('home_dashboard_habits_test_').path}'
      '/habits_data.json',
    );

File _tempGoalsFile() => File(
      '${Directory.systemTemp.createTempSync('home_dashboard_goals_test_').path}'
      '/goals_data.json',
    );

File _tempNotesFile() => File(
      '${Directory.systemTemp.createTempSync('home_dashboard_notes_test_').path}'
      '/notes_data.json',
    );

File _tempOnboardingFile() => File(
      '${Directory.systemTemp.createTempSync('home_dashboard_onboarding_test_').path}'
      '/onboarding_status.json',
    );

Future<AppBootstrap> _boot() => AppBootstrap.boot(
      financeStorageFile: _tempFinanceFile(),
      tasksStorageFile: _tempTasksFile(),
      habitsStorageFile: _tempHabitsFile(),
      goalsStorageFile: _tempGoalsFile(),
      notesStorageFile: _tempNotesFile(),
      onboardingStatusFile: _tempOnboardingFile(),
    );

Widget _buildPage(
  AppBootstrap bootstrap, {
  VoidCallback? onOpenFinance,
}) =>
    MaterialApp(
      home: HomeDashboardPage(
        financeViewModel: bootstrap.registry.get<FinanceHomeViewModel>(),
        tasksViewModel: bootstrap.registry.get<TasksHomeViewModel>(),
        habitsViewModel: bootstrap.registry.get<HabitsHomeViewModel>(),
        goalsViewModel: bootstrap.registry.get<GoalsHomeViewModel>(),
        notesViewModel: bootstrap.registry.get<NotesHomeViewModel>(),
        onOpenFinance: onOpenFinance,
      ),
    );

void main() {
  group('HomeDashboardPage', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      await tester.runAsync(() async {
        final bootstrap = await _boot();
        addTearDown(bootstrap.shutdown);

        await tester.pumpWidget(_buildPage(bootstrap));

        // Finance, Tasks, and Habits module cards each render their own
        // loading indicator independently (design_system ModuleCard —
        // TIS §5 "Loading / Error isolation"). Goals' and Notes' cards are
        // below the default test viewport, so their lazy ListView elements
        // haven't been built yet — asserted once scrolled into view below.
        expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
      });
    });

    testWidgets(
        'shows the greeting header, Finance/Tasks/Habits/Goals/Notes cards, '
        'and placeholder modules once loaded', (tester) async {
      await tester.runAsync(() async {
        final bootstrap = await _boot();
        addTearDown(bootstrap.shutdown);

        await tester.pumpWidget(_buildPage(bootstrap));
        await tester.pumpAndSettle();

        expect(find.text('Finance'), findsOneWidget);
        expect(find.text('No accounts yet'), findsOneWidget);
        expect(find.text('Tasks'), findsOneWidget);
        expect(find.text('Habits'), findsOneWidget);
        // 'Active' appears once each for Tasks and Habits above the fold;
        // Goals' and Notes' cards (also 'Active') are scrolled into view
        // and asserted separately below.
        expect(find.text('Active'), findsNWidgets(2));
        expect(find.text('Completed today'), findsNWidgets(2));

        // The placeholder module grid — and Goals'/Notes' cards — are
        // further down the page than the default 800x600 test viewport
        // shows — a lazy ListView doesn't build off-screen children at all,
        // so each must be scrolled into view before it exists in the tree
        // to assert against. Habits is no longer a placeholder — it now has
        // real data, asserted above.
        await tester.scrollUntilVisible(
          find.text('Goals'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Goals'), findsOneWidget);
        expect(find.text('Active'), findsNWidgets(3));

        await tester.scrollUntilVisible(
          find.text('Notes'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Notes'), findsOneWidget);
        expect(find.text('Active'), findsNWidgets(4));

        for (final label in [
          'Documents',
          'Assets',
          'AI Assistant',
        ]) {
          await tester.scrollUntilVisible(
            find.text(label),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text(label), findsOneWidget);
        }
      });
    });

    testWidgets('tapping the Finance card invokes onOpenFinance',
        (tester) async {
      await tester.runAsync(() async {
        final bootstrap = await _boot();
        addTearDown(bootstrap.shutdown);
        var tapped = false;

        await tester.pumpWidget(_buildPage(bootstrap, onOpenFinance: () => tapped = true));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Finance'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });

    testWidgets('tapping "Open Finance" quick action invokes onOpenFinance',
        (tester) async {
      await tester.runAsync(() async {
        final bootstrap = await _boot();
        addTearDown(bootstrap.shutdown);
        var tapped = false;

        await tester.pumpWidget(_buildPage(bootstrap, onOpenFinance: () => tapped = true));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Open Finance'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Finance'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });

    testWidgets('quick action buttons are absent when no callback is supplied',
        (tester) async {
      await tester.runAsync(() async {
        final bootstrap = await _boot();
        addTearDown(bootstrap.shutdown);

        await tester.pumpWidget(_buildPage(bootstrap));
        await tester.pumpAndSettle();

        expect(find.text('Open Finance'), findsNothing);
        expect(find.text('View Accounts'), findsNothing);
        expect(find.text('View Transactions'), findsNothing);
      });
    });

    testWidgets('pull-to-refresh reloads the Finance summary', (tester) async {
      await tester.runAsync(() async {
        final bootstrap = await _boot();
        addTearDown(bootstrap.shutdown);
        final viewModel = bootstrap.registry.get<FinanceHomeViewModel>();

        await tester.pumpWidget(_buildPage(bootstrap));
        await tester.pumpAndSettle();
        expect(find.text('No accounts yet'), findsOneWidget);

        await viewModel.refresh();
        await tester.pumpAndSettle();

        expect(find.text('No accounts yet'), findsOneWidget);
      });
    });

    testWidgets('adapts the placeholder grid to a wider viewport',
        (tester) async {
      await tester.runAsync(() async {
        final bootstrap = await _boot();
        addTearDown(bootstrap.shutdown);

        tester.view.physicalSize = const Size(1024, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildPage(bootstrap));
        await tester.pumpAndSettle();

        // Still renders every module placeholder at the wider (Expanded)
        // breakpoint — the layout adapts column count, not content.
        await tester.scrollUntilVisible(
          find.text('Documents'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Documents'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('AI Assistant'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('AI Assistant'), findsOneWidget);
      });
    });
  });
}
