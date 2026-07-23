import 'package:feature_finance/finance.dart';
import 'package:feature_habits/habits.dart';
import 'package:feature_tasks/tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_os/app/demo/demo_mode_controller.dart';
import 'package:personal_os/app/demo/switchable_finance_storage.dart';
import 'package:personal_os/app/demo/switchable_habit_storage.dart';
import 'package:personal_os/app/demo/switchable_task_storage.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:personal_os/app/navigation/app_router.dart';
import 'package:personal_os/app/screens/home/home_screen.dart';

/// A minimal, real [DemoModeController] wired to throwaway in-memory
/// executors — these tests only exercise shell/routing mechanics, never
/// actual Finance/Tasks/Habits persistence, so fully-fledged file-backed
/// pairs aren't needed.
DemoModeController _dummyDemoModeController() {
  final realExecutor = InMemoryFinanceDatabaseExecutor();
  final realRunner = InMemoryFinanceTransactionRunner(realExecutor);
  final realTaskExecutor = InMemoryTaskDatabaseExecutor();
  final realTaskRunner = InMemoryTaskTransactionRunner(realTaskExecutor);
  final realHabitExecutor = InMemoryHabitDatabaseExecutor();
  final realHabitRunner = InMemoryHabitTransactionRunner(realHabitExecutor);
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
    workspaceId: 'default-workspace',
  );
}

const AppConfig _testConfig = AppConfig(
  appName: 'Personal OS',
  environment: BuildEnvironment.development,
  version: '0.5.0',
);

const _financeText = 'Finance branch placeholder';
const _homeText = 'Home branch placeholder';
const _settingsText = 'Settings branch placeholder';
const _tasksText = 'Tasks branch placeholder';
const _habitsText = 'Habits branch placeholder';

/// A minimal stand-in for Finance's real routes — a `StatefulShellBranch`
/// requires at least one `GoRoute` descendant to derive a default location,
/// and these tests only exercise shell/routing mechanics, not Finance's
/// actual pages (which have their own navigation tests).
List<RouteBase> _dummyFinanceRoutes() => [
      GoRoute(
        path: '/finance',
        name: 'finance',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text(_financeText)),
        ),
      ),
    ];

/// A minimal stand-in for the real Home Dashboard builder — these tests
/// only exercise shell/routing mechanics (the real [HomeDashboardPage]'s own
/// content/behavior has its own tests).
Widget _dummyHomeBuilder(BuildContext context, GoRouterState state) =>
    const Scaffold(body: Center(child: Text(_homeText)));

/// A minimal stand-in for the real Settings page builder — see
/// [_dummyHomeBuilder].
Widget _dummySettingsBuilder(BuildContext context, GoRouterState state) =>
    const Scaffold(body: Center(child: Text(_settingsText)));

/// A minimal stand-in for the real Tasks page builder — see
/// [_dummyHomeBuilder].
Widget _dummyTasksBuilder(BuildContext context, GoRouterState state) =>
    const Scaffold(body: Center(child: Text(_tasksText)));

/// A minimal stand-in for the real Habits page builder — see
/// [_dummyHomeBuilder].
Widget _dummyHabitsBuilder(BuildContext context, GoRouterState state) =>
    const Scaffold(body: Center(child: Text(_habitsText)));

/// Pumps [routerConfig] at a Compact-width viewport (<600dp) so [AppShell]
/// renders its bottom `NavigationBar` — the layout these navigation tests
/// exercise (adaptive `NavigationRail` behavior at wider widths is a
/// visual/responsive concern, not a routing-correctness one).
Future<void> _pumpCompact(WidgetTester tester, GoRouter routerConfig) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp.router(routerConfig: routerConfig));
  await tester.pumpAndSettle();
}

void main() {
  group('AppRouter', () {
    late GoRouter router;

    setUp(() => router = AppRouter.create(
          config: _testConfig,
          homeBuilder: _dummyHomeBuilder,
          settingsBuilder: _dummySettingsBuilder,
          tasksBuilder: _dummyTasksBuilder,
          habitsBuilder: _dummyHabitsBuilder,
          demoModeController: _dummyDemoModeController(),
          financeRoutes: _dummyFinanceRoutes(),
        ));
    tearDown(() => router.dispose());

    test('diagnostics path constant is "/diagnostics"', () {
      expect(AppRouter.diagnosticsPath, '/diagnostics');
    });

    test('diagnostics name constant is "diagnostics"', () {
      expect(AppRouter.diagnosticsName, 'diagnostics');
    });

    test('router has at least one route', () {
      expect(router.configuration.routes, isNotEmpty);
    });

    test('create() returns a GoRouter instance', () {
      expect(router, isA<GoRouter>());
    });

    testWidgets(
        'default initial location (no explicit initialLocation) shows the '
        'Home placeholder inside the shell', (tester) async {
      await _pumpCompact(tester, router);
      expect(find.text(_homeText), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('an explicit initialLocation overrides the default',
        (tester) async {
      final customRouter = AppRouter.create(
        config: _testConfig,
        homeBuilder: _dummyHomeBuilder,
        settingsBuilder: _dummySettingsBuilder,
        tasksBuilder: _dummyTasksBuilder,
        habitsBuilder: _dummyHabitsBuilder,
        demoModeController: _dummyDemoModeController(),
        financeRoutes: _dummyFinanceRoutes(),
        initialLocation: AppRouter.diagnosticsPath,
      );
      addTearDown(customRouter.dispose);
      await _pumpCompact(tester, customRouter);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    group('shell navigation (compact / bottom nav)', () {
      testWidgets(
          'bottom nav shows Home, Finance, Tasks, Habits, and Settings destinations',
          (tester) async {
        await _pumpCompact(tester, router);

        final navBar = find.byType(NavigationBar);
        expect(
          find.descendant(of: navBar, matching: find.text('Home')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBar, matching: find.text('Finance')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBar, matching: find.text('Tasks')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBar, matching: find.text('Habits')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBar, matching: find.text('Settings')),
          findsOneWidget,
        );
      });

      testWidgets('tapping Tasks destination shows the Tasks branch',
          (tester) async {
        await _pumpCompact(tester, router);

        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();

        expect(find.text(_tasksText), findsOneWidget);
      });

      testWidgets('tapping Habits destination shows the Habits branch',
          (tester) async {
        await _pumpCompact(tester, router);

        await tester.tap(find.text('Habits'));
        await tester.pumpAndSettle();

        expect(find.text(_habitsText), findsOneWidget);
      });

      testWidgets('tapping Finance destination shows the Finance branch',
          (tester) async {
        await _pumpCompact(tester, router);

        await tester.tap(find.text('Finance'));
        await tester.pumpAndSettle();

        expect(find.text(_financeText), findsOneWidget);
      });

      testWidgets('tapping Settings destination shows the Settings branch',
          (tester) async {
        await _pumpCompact(tester, router);

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        expect(find.text(_settingsText), findsOneWidget);
      });

      testWidgets(
          'pressing the system back button while on the Finance branch '
          'returns to Home instead of exiting the app', (tester) async {
        await _pumpCompact(tester, router);

        await tester.tap(find.text('Finance'));
        await tester.pumpAndSettle();
        expect(find.text(_financeText), findsOneWidget);

        // Simulates the Android back button / system pop-route request —
        // the real end-to-end mechanism PopScope intercepts, not just its
        // constructor field.
        // ignore: deprecated_member_use
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text(_homeText), findsOneWidget);
        expect(find.text(_financeText), findsNothing);
      });

      testWidgets(
          'pressing the system back button while on Home does not '
          're-navigate within the shell (default pop-to-exit applies)',
          (tester) async {
        await _pumpCompact(tester, router);
        expect(find.text(_homeText), findsOneWidget);

        // ignore: deprecated_member_use
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Home has nowhere else to go within this shell — it must still be
        // showing Home (PopScope allowed the default pop; there was simply
        // nothing above it in this test's router to pop to).
        expect(find.text(_homeText), findsOneWidget);
      });
    });

    group('shell navigation (expanded / rail)', () {
      testWidgets('navigation rail is used at wide viewport widths',
          (tester) async {
        tester.view.physicalSize = const Size(1024, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });
    });
  });
}
