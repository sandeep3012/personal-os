import 'package:feature_finance/finance.dart';
import 'package:feature_goals/goals.dart';
import 'package:feature_habits/habits.dart';
import 'package:feature_tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/app/demo/demo_mode_controller.dart';
import 'package:personal_os/app/demo/switchable_finance_storage.dart';
import 'package:personal_os/app/demo/switchable_goal_storage.dart';
import 'package:personal_os/app/demo/switchable_habit_storage.dart';
import 'package:personal_os/app/demo/switchable_task_storage.dart';

const _ws = 'ws-demo-test';

Future<int> _accountCount(IFinanceDatabaseExecutor executor) async {
  final rows = await executor.query(
    'SELECT * FROM accounts WHERE workspace_id = ? AND deleted_at IS NULL',
    [_ws],
  );
  return rows.length;
}

Future<int> _transactionCount(IFinanceDatabaseExecutor executor) async {
  final rows = await executor.query(
    'SELECT * FROM transactions WHERE workspace_id = ? AND deleted_at IS NULL',
    [_ws],
  );
  return rows.length;
}

final class _Harness {
  _Harness()
      : realExecutor = InMemoryFinanceDatabaseExecutor(),
        realRunner = InMemoryFinanceTransactionRunner(InMemoryFinanceDatabaseExecutor()),
        realTaskExecutor = InMemoryTaskDatabaseExecutor(),
        realTaskRunner = InMemoryTaskTransactionRunner(InMemoryTaskDatabaseExecutor()),
        realHabitExecutor = InMemoryHabitDatabaseExecutor(),
        realHabitRunner = InMemoryHabitTransactionRunner(InMemoryHabitDatabaseExecutor()),
        realGoalExecutor = InMemoryGoalDatabaseExecutor(),
        realGoalRunner = InMemoryGoalTransactionRunner(InMemoryGoalDatabaseExecutor()) {
    executor = SwitchableFinanceDatabaseExecutor(realExecutor);
    runner = SwitchableFinanceTransactionRunner(realRunner);
    taskExecutor = SwitchableTaskDatabaseExecutor(realTaskExecutor);
    taskRunner = SwitchableTaskTransactionRunner(realTaskRunner);
    habitExecutor = SwitchableHabitDatabaseExecutor(realHabitExecutor);
    habitRunner = SwitchableHabitTransactionRunner(realHabitRunner);
    goalExecutor = SwitchableGoalDatabaseExecutor(realGoalExecutor);
    goalRunner = SwitchableGoalTransactionRunner(realGoalRunner);
    controller = DemoModeController(
      financeExecutor: executor,
      financeRunner: runner,
      realFinanceExecutor: realExecutor,
      realFinanceRunner: realRunner,
      taskExecutor: taskExecutor,
      taskRunner: taskRunner,
      realTaskExecutor: realTaskExecutor,
      realTaskRunner: realTaskRunner,
      habitExecutor: habitExecutor,
      habitRunner: habitRunner,
      realHabitExecutor: realHabitExecutor,
      realHabitRunner: realHabitRunner,
      goalExecutor: goalExecutor,
      goalRunner: goalRunner,
      realGoalExecutor: realGoalExecutor,
      realGoalRunner: realGoalRunner,
      workspaceId: _ws,
    );
  }

  final InMemoryFinanceDatabaseExecutor realExecutor;
  final InMemoryFinanceTransactionRunner realRunner;
  final InMemoryTaskDatabaseExecutor realTaskExecutor;
  final InMemoryTaskTransactionRunner realTaskRunner;
  final InMemoryHabitDatabaseExecutor realHabitExecutor;
  final InMemoryHabitTransactionRunner realHabitRunner;
  final InMemoryGoalDatabaseExecutor realGoalExecutor;
  final InMemoryGoalTransactionRunner realGoalRunner;
  late final SwitchableFinanceDatabaseExecutor executor;
  late final SwitchableFinanceTransactionRunner runner;
  late final SwitchableTaskDatabaseExecutor taskExecutor;
  late final SwitchableTaskTransactionRunner taskRunner;
  late final SwitchableHabitDatabaseExecutor habitExecutor;
  late final SwitchableHabitTransactionRunner habitRunner;
  late final SwitchableGoalDatabaseExecutor goalExecutor;
  late final SwitchableGoalTransactionRunner goalRunner;
  late final DemoModeController controller;
}

void main() {
  group('DemoModeController — enable', () {
    test('loads realistic sample accounts and transactions', () async {
      final harness = _Harness();

      await harness.controller.enableDemoMode();

      expect(harness.controller.isDemoMode, isTrue);
      expect(await _accountCount(harness.executor), 3);
      expect(await _transactionCount(harness.executor), greaterThanOrEqualTo(15));
    });

    test('never modifies the real (pre-existing) data', () async {
      final harness = _Harness();
      await harness.realExecutor.execute(
        'INSERT INTO accounts '
        '(account_id, workspace_id, name, account_type, currency, '
        'opening_balance_minor, is_active, created_at, updated_at, deleted_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'real-acc-1',
          _ws,
          "Rohan's Real Account",
          'savings',
          'INR',
          100000,
          1,
          DateTime(2024).toIso8601String(),
          DateTime(2024).toIso8601String(),
          null,
        ],
      );

      await harness.controller.enableDemoMode();

      // While in Demo Mode, the switchable executor only sees demo rows —
      // the real account is not merged in or otherwise visible.
      final demoRows = await harness.executor.query(
        'SELECT * FROM accounts WHERE workspace_id = ? AND deleted_at IS NULL',
        [_ws],
      );
      expect(demoRows.any((r) => r['account_id'] == 'real-acc-1'), isFalse);

      // The real executor itself, untouched throughout, still has exactly
      // the one row written before Demo Mode was ever enabled.
      expect(await _accountCount(harness.realExecutor), 1);
    });

    test('bumps generation so the app root can force a remount', () async {
      final harness = _Harness();
      final before = harness.controller.generation;

      await harness.controller.enableDemoMode();

      expect(harness.controller.generation, before + 1);
    });
  });

  group('DemoModeController — exit', () {
    test('switches back to the real data source', () async {
      final harness = _Harness();
      await harness.realExecutor.execute(
        'INSERT INTO accounts '
        '(account_id, workspace_id, name, account_type, currency, '
        'opening_balance_minor, is_active, created_at, updated_at, deleted_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'real-acc-1',
          _ws,
          'Priya\'s Checking',
          'checking',
          'INR',
          50000,
          1,
          DateTime(2024).toIso8601String(),
          DateTime(2024).toIso8601String(),
          null,
        ],
      );

      await harness.controller.enableDemoMode();
      expect(await _accountCount(harness.executor), 3);

      await harness.controller.exitDemoMode();

      expect(harness.controller.isDemoMode, isFalse);
      // Back to seeing only the real, single account — the real data was
      // never touched by the demo excursion.
      expect(await _accountCount(harness.executor), 1);
    });

    test('bumps generation', () async {
      final harness = _Harness();
      await harness.controller.enableDemoMode();
      final beforeExit = harness.controller.generation;

      await harness.controller.exitDemoMode();

      expect(harness.controller.generation, beforeExit + 1);
    });
  });

  group('DemoModeController — reset', () {
    test('is a no-op when not currently in Demo Mode', () async {
      final harness = _Harness();
      final before = harness.controller.generation;

      await harness.controller.resetDemoData();

      expect(harness.controller.generation, before);
      expect(harness.controller.isDemoMode, isFalse);
    });

    test('discards and reloads a fresh demo dataset while in Demo Mode',
        () async {
      final harness = _Harness();
      await harness.controller.enableDemoMode();

      // Simulate the user having edited the demo data.
      await harness.executor.execute(
        'INSERT INTO accounts '
        '(account_id, workspace_id, name, account_type, currency, '
        'opening_balance_minor, is_active, created_at, updated_at, deleted_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'extra-demo-acc',
          _ws,
          'Extra Demo Account',
          'cash',
          'INR',
          1000,
          1,
          DateTime(2024).toIso8601String(),
          DateTime(2024).toIso8601String(),
          null,
        ],
      );
      expect(await _accountCount(harness.executor), 4);

      await harness.controller.resetDemoData();

      // Back to exactly the fresh seed's three accounts — the extra one is
      // gone, and Demo Mode is still active.
      expect(harness.controller.isDemoMode, isTrue);
      expect(await _accountCount(harness.executor), 3);
    });
  });
}
