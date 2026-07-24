import 'dart:io';

import 'package:feature_finance/finance.dart';
import 'package:feature_goals/goals.dart';
import 'package:feature_habits/habits.dart';
import 'package:feature_notes/notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:platform_core/logging/i_logger.dart';
import 'package:personal_os/app/bootstrap/app_bootstrap.dart';

/// Every test passes an explicit [financeStorageFile]/[onboardingStatusFile]
/// so [AppBootstrap.boot] never resolves either via `path_provider` — that
/// plugin's platform channel isn't available under `flutter test`, and isn't
/// needed here: the whole point of these tests is to control exactly which
/// file Finance persists to (or, for most tests, simply to use a private
/// throwaway file per test).
File _tempFinanceFile() => File(
      '${Directory.systemTemp.createTempSync('finance_bootstrap_test_').path}'
      '/finance_data.json',
    );

File _tempTasksFile() => File(
      '${Directory.systemTemp.createTempSync('tasks_bootstrap_test_').path}'
      '/tasks_data.json',
    );

File _tempHabitsFile() => File(
      '${Directory.systemTemp.createTempSync('habits_bootstrap_test_').path}'
      '/habits_data.json',
    );

File _tempGoalsFile() => File(
      '${Directory.systemTemp.createTempSync('goals_bootstrap_test_').path}'
      '/goals_data.json',
    );

File _tempNotesFile() => File(
      '${Directory.systemTemp.createTempSync('notes_bootstrap_test_').path}'
      '/notes_data.json',
    );

File _tempOnboardingFile() => File(
      '${Directory.systemTemp.createTempSync('onboarding_bootstrap_test_').path}'
      '/onboarding_status.json',
    );

Future<AppBootstrap> _boot({
  File? financeStorageFile,
  File? tasksStorageFile,
  File? habitsStorageFile,
  File? goalsStorageFile,
  File? notesStorageFile,
  File? onboardingStatusFile,
}) =>
    AppBootstrap.boot(
      financeStorageFile: financeStorageFile ?? _tempFinanceFile(),
      tasksStorageFile: tasksStorageFile ?? _tempTasksFile(),
      habitsStorageFile: habitsStorageFile ?? _tempHabitsFile(),
      goalsStorageFile: goalsStorageFile ?? _tempGoalsFile(),
      notesStorageFile: notesStorageFile ?? _tempNotesFile(),
      onboardingStatusFile: onboardingStatusFile ?? _tempOnboardingFile(),
    );

void main() {
  group('AppBootstrap', () {
    test('boot() completes without error', () async {
      final bootstrap = await _boot();
      expect(bootstrap.isBooted, isTrue);
      expect(bootstrap.isShutdown, isFalse);
      await bootstrap.shutdown();
    });

    test('registry has ILogger registered after boot', () async {
      final bootstrap = await _boot();
      expect(bootstrap.registry.isRegistered<ILogger>(), isTrue);
      await bootstrap.shutdown();
    });

    test('registry has AppConfig registered after boot', () async {
      final bootstrap = await _boot();
      expect(bootstrap.registry.isRegistered<AppConfig>(), isTrue);
      await bootstrap.shutdown();
    });

    test('config has correct app name', () async {
      final bootstrap = await _boot();
      expect(bootstrap.config.appName, 'Personal OS');
      await bootstrap.shutdown();
    });

    test('config has development environment', () async {
      final bootstrap = await _boot();
      expect(bootstrap.config.environment, BuildEnvironment.development);
      await bootstrap.shutdown();
    });

    test('config has version 0.6.0', () async {
      final bootstrap = await _boot();
      expect(bootstrap.config.version, '0.6.0');
      await bootstrap.shutdown();
    });

    test('shutdown() completes without error', () async {
      final bootstrap = await _boot();
      await expectLater(bootstrap.shutdown(), completes);
      expect(bootstrap.isShutdown, isTrue);
    });

    test('ILogger can log without throwing', () async {
      final bootstrap = await _boot();
      final logger = bootstrap.registry.get<ILogger>();
      expect(
        () {
          logger.info('test message');
          logger.debug('debug message');
          logger.warning('warning message');
        },
        returnsNormally,
      );
      await bootstrap.shutdown();
    });

    group('Finance persistence binding', () {
      // Regression coverage for the crash a manual test run surfaced:
      // "RegistryException: No registration found for type
      // IFinanceDatabaseExecutor" — AppBootstrap.boot() previously never
      // registered a binding for IFinanceDatabaseExecutor/
      // IFinanceTransactionRunner before FinanceModule, so resolving any
      // Finance repository (transitively, any Finance ViewModel) threw the
      // moment a Finance page was opened. FinanceStorageModule now supplies
      // that binding.
      test('IFinanceDatabaseExecutor is registered after boot', () async {
        final bootstrap = await _boot();
        expect(
          bootstrap.registry.isRegistered<IFinanceDatabaseExecutor>(),
          isTrue,
        );
        await bootstrap.shutdown();
      });

      test('IFinanceTransactionRunner is registered after boot', () async {
        final bootstrap = await _boot();
        expect(
          bootstrap.registry.isRegistered<IFinanceTransactionRunner>(),
          isTrue,
        );
        await bootstrap.shutdown();
      });

      test('every Finance ViewModel resolves without throwing', () async {
        final bootstrap = await _boot();
        expect(
          () {
            bootstrap.registry.get<FinanceHomeViewModel>();
            bootstrap.registry.get<AccountsViewModel>();
            bootstrap.registry.get<TransactionsViewModel>();
            bootstrap.registry.get<CategoriesViewModel>();
          },
          returnsNormally,
        );
        await bootstrap.shutdown();
      });

      test('GetAccountsUseCase resolves and executes against the '
          'file-backed persistence layer', () async {
        final bootstrap = await _boot();
        final viewModel = bootstrap.registry.get<AccountsViewModel>();

        await expectLater(viewModel.load(), completes);
        expect(viewModel.state.isError, isFalse);

        await bootstrap.shutdown();
      });
    });

    group('Habits persistence binding', () {
      test('IHabitDatabaseExecutor is registered after boot', () async {
        final bootstrap = await _boot();
        expect(
          bootstrap.registry.isRegistered<IHabitDatabaseExecutor>(),
          isTrue,
        );
        await bootstrap.shutdown();
      });

      test('IHabitTransactionRunner is registered after boot', () async {
        final bootstrap = await _boot();
        expect(
          bootstrap.registry.isRegistered<IHabitTransactionRunner>(),
          isTrue,
        );
        await bootstrap.shutdown();
      });

      test('every Habits ViewModel resolves without throwing', () async {
        final bootstrap = await _boot();
        expect(
          () {
            bootstrap.registry.get<HabitsHomeViewModel>();
            bootstrap.registry.get<HabitsViewModel>();
          },
          returnsNormally,
        );
        await bootstrap.shutdown();
      });

      test('GetHabitsUseCase resolves and executes against the '
          'file-backed persistence layer', () async {
        final bootstrap = await _boot();
        final viewModel = bootstrap.registry.get<HabitsViewModel>();

        await expectLater(viewModel.load(), completes);
        expect(viewModel.state.isError, isFalse);

        await bootstrap.shutdown();
      });
    });

    group('Goals persistence binding', () {
      test('IGoalDatabaseExecutor is registered after boot', () async {
        final bootstrap = await _boot();
        expect(
          bootstrap.registry.isRegistered<IGoalDatabaseExecutor>(),
          isTrue,
        );
        await bootstrap.shutdown();
      });

      test('IGoalTransactionRunner is registered after boot', () async {
        final bootstrap = await _boot();
        expect(
          bootstrap.registry.isRegistered<IGoalTransactionRunner>(),
          isTrue,
        );
        await bootstrap.shutdown();
      });

      test('every Goals ViewModel resolves without throwing', () async {
        final bootstrap = await _boot();
        expect(
          () {
            bootstrap.registry.get<GoalsHomeViewModel>();
            bootstrap.registry.get<GoalsViewModel>();
          },
          returnsNormally,
        );
        await bootstrap.shutdown();
      });

      test('GetGoalsUseCase resolves and executes against the '
          'file-backed persistence layer', () async {
        final bootstrap = await _boot();
        final viewModel = bootstrap.registry.get<GoalsViewModel>();

        await expectLater(viewModel.load(), completes);
        expect(viewModel.state.isError, isFalse);

        await bootstrap.shutdown();
      });
    });

    group('Notes persistence binding', () {
      test('INoteDatabaseExecutor is registered after boot', () async {
        final bootstrap = await _boot();
        expect(
          bootstrap.registry.isRegistered<INoteDatabaseExecutor>(),
          isTrue,
        );
        await bootstrap.shutdown();
      });

      test('INoteTransactionRunner is registered after boot', () async {
        final bootstrap = await _boot();
        expect(
          bootstrap.registry.isRegistered<INoteTransactionRunner>(),
          isTrue,
        );
        await bootstrap.shutdown();
      });

      test('every Notes ViewModel resolves without throwing', () async {
        final bootstrap = await _boot();
        expect(
          () {
            bootstrap.registry.get<NotesHomeViewModel>();
            bootstrap.registry.get<NotesViewModel>();
          },
          returnsNormally,
        );
        await bootstrap.shutdown();
      });

      test('GetNotesUseCase resolves and executes against the '
          'file-backed persistence layer', () async {
        final bootstrap = await _boot();
        final viewModel = bootstrap.registry.get<NotesViewModel>();

        await expectLater(viewModel.load(), completes);
        expect(viewModel.state.isError, isFalse);

        await bootstrap.shutdown();
      });
    });

    group('Finance data survives an app restart', () {
      // Regression coverage for the "kill and relaunch the app" acceptance
      // scenario: data written through the registered
      // IFinanceDatabaseExecutor must still be readable after a second,
      // completely independent AppBootstrap.boot() call against the same
      // storage file — proving persistence is disk-backed, not merely
      // process-lifetime in-memory state.
      test(
          'a row written during one boot is still present after a second '
          'boot() against the same file', () async {
        final storageFile = _tempFinanceFile();

        final firstBoot = await _boot(financeStorageFile: storageFile);
        final firstExecutor =
            firstBoot.registry.get<IFinanceDatabaseExecutor>();
        await firstExecutor.execute(
          'INSERT INTO accounts '
          '(account_id, workspace_id, name, account_type, currency, '
          'opening_balance_minor, is_active, created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'acc-restart-test',
            'default-workspace',
            'Restart Test Account',
            'savings',
            'INR',
            10000,
            1,
            '2024-01-01T00:00:00.000',
            '2024-01-01T00:00:00.000',
            null,
          ],
        );
        await firstBoot.shutdown();

        // Simulates "kill the app and launch it again": a brand-new
        // AppBootstrap.boot() call, independent runtime, same file.
        final secondBoot = await _boot(financeStorageFile: storageFile);
        final secondExecutor =
            secondBoot.registry.get<IFinanceDatabaseExecutor>();
        final rows = await secondExecutor.query(
          'SELECT * FROM accounts WHERE account_id = ? '
          'AND workspace_id = ? AND deleted_at IS NULL',
          ['acc-restart-test', 'default-workspace'],
        );

        expect(rows, hasLength(1));
        expect(rows.single['name'], 'Restart Test Account');

        await secondBoot.shutdown();
      });
    });
  });
}
