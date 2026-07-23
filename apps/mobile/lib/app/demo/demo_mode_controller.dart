import 'package:feature_finance/finance.dart';
import 'package:feature_goals/goals.dart';
import 'package:feature_habits/habits.dart';
import 'package:feature_tasks/tasks.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_os/app/demo/demo_finance_seed_data.dart';
import 'package:personal_os/app/demo/demo_goal_seed_data.dart';
import 'package:personal_os/app/demo/demo_habit_seed_data.dart';
import 'package:personal_os/app/demo/demo_task_seed_data.dart';
import 'package:personal_os/app/demo/switchable_finance_storage.dart';
import 'package:personal_os/app/demo/switchable_goal_storage.dart';
import 'package:personal_os/app/demo/switchable_habit_storage.dart';
import 'package:personal_os/app/demo/switchable_task_storage.dart';

/// Owns whether the app is currently showing sample data instead of the
/// user's real data, and performs the swap — across every module that
/// participates in Demo Mode (Milestone 6 Part A; extended for Tasks in
/// Milestone 7; extended for Habits thereafter).
///
/// This is the one place that knows about "demo vs. real" — every
/// repository, use case, and ViewModel in Finance, Tasks, and Habits alike
/// resolves its own feature's switchable executor/runner pair (registered
/// once, never replaced) and stays completely unaware that a swap ever
/// happens. Presentation code never branches on `isDemoMode` except to
/// decide what to *show* (the [DemoModeBanner], the Settings section) — it
/// never touches persistence directly.
///
/// Adding a further module to Demo Mode means adding one more switchable
/// pair + seed-data call here, mirroring the Finance/Tasks/Habits pattern
/// exactly — no new controller class, no per-module demo infrastructure.
///
/// [generation] increments on every enable/exit/reset; the app root uses it
/// as a [ValueKey] to force a full remount of the shell (every already-open
/// page's ViewModel is a DI factory — see `FinanceModule`/`TasksModule`/
/// `HabitsModule` — so a remount is sufficient to make every page reload
/// against the newly active data source, without each page needing to
/// listen for a demo-mode change itself).
final class DemoModeController extends ChangeNotifier {
  DemoModeController({
    required SwitchableFinanceDatabaseExecutor financeExecutor,
    required SwitchableFinanceTransactionRunner financeRunner,
    required IFinanceDatabaseExecutor realFinanceExecutor,
    required IFinanceTransactionRunner realFinanceRunner,
    required SwitchableTaskDatabaseExecutor taskExecutor,
    required SwitchableTaskTransactionRunner taskRunner,
    required ITaskDatabaseExecutor realTaskExecutor,
    required ITaskTransactionRunner realTaskRunner,
    required SwitchableHabitDatabaseExecutor habitExecutor,
    required SwitchableHabitTransactionRunner habitRunner,
    required IHabitDatabaseExecutor realHabitExecutor,
    required IHabitTransactionRunner realHabitRunner,
    required SwitchableGoalDatabaseExecutor goalExecutor,
    required SwitchableGoalTransactionRunner goalRunner,
    required IGoalDatabaseExecutor realGoalExecutor,
    required IGoalTransactionRunner realGoalRunner,
    required this.workspaceId,
  })  : _financeExecutor = financeExecutor,
        _financeRunner = financeRunner,
        _realFinanceExecutor = realFinanceExecutor,
        _realFinanceRunner = realFinanceRunner,
        _taskExecutor = taskExecutor,
        _taskRunner = taskRunner,
        _realTaskExecutor = realTaskExecutor,
        _realTaskRunner = realTaskRunner,
        _habitExecutor = habitExecutor,
        _habitRunner = habitRunner,
        _realHabitExecutor = realHabitExecutor,
        _realHabitRunner = realHabitRunner,
        _goalExecutor = goalExecutor,
        _goalRunner = goalRunner,
        _realGoalExecutor = realGoalExecutor,
        _realGoalRunner = realGoalRunner;

  final SwitchableFinanceDatabaseExecutor _financeExecutor;
  final SwitchableFinanceTransactionRunner _financeRunner;
  final IFinanceDatabaseExecutor _realFinanceExecutor;
  final IFinanceTransactionRunner _realFinanceRunner;

  final SwitchableTaskDatabaseExecutor _taskExecutor;
  final SwitchableTaskTransactionRunner _taskRunner;
  final ITaskDatabaseExecutor _realTaskExecutor;
  final ITaskTransactionRunner _realTaskRunner;

  final SwitchableHabitDatabaseExecutor _habitExecutor;
  final SwitchableHabitTransactionRunner _habitRunner;
  final IHabitDatabaseExecutor _realHabitExecutor;
  final IHabitTransactionRunner _realHabitRunner;

  final SwitchableGoalDatabaseExecutor _goalExecutor;
  final SwitchableGoalTransactionRunner _goalRunner;
  final IGoalDatabaseExecutor _realGoalExecutor;
  final IGoalTransactionRunner _realGoalRunner;

  final String workspaceId;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  var _generation = 0;

  /// Bumped on every mode change — see class doc for why the app root keys
  /// off this to force a full remount.
  int get generation => _generation;

  /// Switches every participating module (Finance, Tasks, Habits) to a
  /// freshly seeded in-memory demo dataset. The user's real (file-backed)
  /// data is left completely untouched — demo writes only ever land in the
  /// fresh in-memory stores created here.
  Future<void> enableDemoMode() async {
    final demoFinanceExecutor = InMemoryFinanceDatabaseExecutor();
    await DemoFinanceSeedData.seed(demoFinanceExecutor, workspaceId: workspaceId);
    _financeExecutor.switchTo(demoFinanceExecutor);
    _financeRunner.switchTo(InMemoryFinanceTransactionRunner(demoFinanceExecutor));

    final demoTaskExecutor = InMemoryTaskDatabaseExecutor();
    await DemoTaskSeedData.seed(demoTaskExecutor, workspaceId: workspaceId);
    _taskExecutor.switchTo(demoTaskExecutor);
    _taskRunner.switchTo(InMemoryTaskTransactionRunner(demoTaskExecutor));

    final demoHabitExecutor = InMemoryHabitDatabaseExecutor();
    await DemoHabitSeedData.seed(demoHabitExecutor, workspaceId: workspaceId);
    _habitExecutor.switchTo(demoHabitExecutor);
    _habitRunner.switchTo(InMemoryHabitTransactionRunner(demoHabitExecutor));

    final demoGoalExecutor = InMemoryGoalDatabaseExecutor();
    await DemoGoalSeedData.seed(demoGoalExecutor, workspaceId: workspaceId);
    _goalExecutor.switchTo(demoGoalExecutor);
    _goalRunner.switchTo(InMemoryGoalTransactionRunner(demoGoalExecutor));

    _isDemoMode = true;
    _generation++;
    notifyListeners();
  }

  /// Switches every participating module back to the user's real
  /// (file-backed) data. Whatever was in the demo datasets is discarded —
  /// none of it was ever persisted anywhere.
  Future<void> exitDemoMode() async {
    _financeExecutor.switchTo(_realFinanceExecutor);
    _financeRunner.switchTo(_realFinanceRunner);
    _taskExecutor.switchTo(_realTaskExecutor);
    _taskRunner.switchTo(_realTaskRunner);
    _habitExecutor.switchTo(_realHabitExecutor);
    _habitRunner.switchTo(_realHabitRunner);
    _goalExecutor.switchTo(_realGoalExecutor);
    _goalRunner.switchTo(_realGoalRunner);

    _isDemoMode = false;
    _generation++;
    notifyListeners();
  }

  /// Discards the current demo datasets and reseeds fresh ones for every
  /// participating module. A no-op if not currently in Demo Mode.
  Future<void> resetDemoData() async {
    if (!_isDemoMode) return;
    await enableDemoMode();
  }
}
