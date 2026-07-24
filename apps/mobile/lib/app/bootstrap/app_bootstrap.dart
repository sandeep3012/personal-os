import 'dart:io';

import 'package:application/application.dart';
import 'package:feature_calendar/calendar.dart';
import 'package:feature_finance/finance.dart';
import 'package:feature_goals/goals.dart';
import 'package:feature_habits/habits.dart';
import 'package:feature_notes/notes.dart';
import 'package:feature_sample/sample.dart';
import 'package:feature_tasks/tasks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/logging/i_logger.dart';
import 'package:platform_runtime/bootstrap/runtime_bootstrap.dart';
import 'package:personal_os/app/bootstrap/app_module.dart';
import 'package:personal_os/app/bootstrap/calendar_storage_module.dart';
import 'package:personal_os/app/bootstrap/finance_storage_module.dart';
import 'package:personal_os/app/bootstrap/goals_storage_module.dart';
import 'package:personal_os/app/bootstrap/habits_storage_module.dart';
import 'package:personal_os/app/bootstrap/notes_storage_module.dart';
import 'package:personal_os/app/bootstrap/tasks_storage_module.dart';
import 'package:personal_os/app/demo/demo_mode_controller.dart';
import 'package:personal_os/app/demo/demo_module.dart';
import 'package:personal_os/app/demo/switchable_calendar_storage.dart';
import 'package:personal_os/app/demo/switchable_finance_storage.dart';
import 'package:personal_os/app/demo/switchable_goal_storage.dart';
import 'package:personal_os/app/demo/switchable_habit_storage.dart';
import 'package:personal_os/app/demo/switchable_note_storage.dart';
import 'package:personal_os/app/demo/switchable_task_storage.dart';
import 'package:personal_os/app/onboarding/onboarding_module.dart';
import 'package:personal_os/app/onboarding/onboarding_status_store.dart';

/// Orchestrates the Personal OS application startup and shutdown.
///
/// [AppBootstrap] is the single composition root for the application. It
/// creates the [RuntimeBootstrap], registers all modules in the correct order,
/// boots the runtime, and exposes the resulting service registry.
///
/// ## Module registration order (required)
///
/// ```
/// AppModule              — ILogger, AppConfig
/// ApplicationModule      — IEventBus, RouteRegistry, ApplicationRouter,
///                          StartupPipeline, FeatureRegistry
/// FinanceStorageModule   — IFinanceDatabaseExecutor, IFinanceTransactionRunner
///                          (the external persistence binding FinanceModule
///                          expects but does not self-register — see its
///                          docs)
/// FinanceModule          — persistence (DAOs, mappers, repositories),
///                          domain services, specifications, use cases,
///                          ViewModels, routes, Dashboard/Accounts/
///                          Transactions/Categories pages
/// TasksStorageModule     — ITaskDatabaseExecutor, ITaskTransactionRunner
///                          (mirrors FinanceStorageModule for Tasks)
/// TasksModule            — persistence, use cases, ViewModels, routes,
///                          the Tasks list page (mirrors FinanceModule)
/// SampleModule           — SampleService, route /sample, SampleStartupStep
/// ```
///
/// [ApplicationModule] **must** precede all [FeatureModule]s so that
/// [FeatureRegistry], [RouteRegistry], and [StartupPipeline] exist in the
/// DI container when feature modules call [FeatureModule.register].
///
/// [FinanceStorageModule] **must** precede [FinanceModule]: without it,
/// resolving any Finance repository (transitively, any Finance ViewModel)
/// throws `RegistryException: No registration found for type
/// IFinanceDatabaseExecutor` — [FinanceModule]'s persistence bindings are
/// lazy singletons that only fail at first resolution, not at `register()`
/// time, so this omission previously went unnoticed until a Finance page
/// was actually opened.
///
/// ## Finance storage file
///
/// [FinanceStorageModule] needs an already-opened
/// [FileBackedFinanceDatabaseExecutor], and opening one means resolving a
/// file path (via `path_provider` in production) and reading it if it
/// exists — both async, so this cannot happen inside the synchronous
/// [RuntimeModule.register] hook. [boot] performs that open itself, before
/// constructing [RuntimeBootstrap], and accepts an optional
/// [financeStorageFile] override so tests can point it at a temporary file
/// instead of touching `path_provider`'s platform channel.
///
/// ## Startup hierarchy
///
/// ```
/// RuntimeBootstrap.boot()       (platform_runtime — infrastructure)
///   ↓
/// StartupPipeline.execute()     (application — orchestration)
///   ↓
/// SampleStartupStep             (feature — marks SampleService as loaded)
/// ```
final class AppBootstrap {
  AppBootstrap._({
    required RuntimeBootstrap runtimeBootstrap,
    required this.needsOnboarding,
  }) : _runtime = runtimeBootstrap;

  final RuntimeBootstrap _runtime;

  /// Read-only view of all registered services, available after [boot].
  IServiceLocator get registry => _runtime.registry;

  /// Whether [boot] has completed.
  bool get isBooted => _runtime.isBooted;

  /// Whether [shutdown] has completed.
  bool get isShutdown => _runtime.isShutdown;

  /// Convenience accessor for [AppConfig] registered by [AppModule].
  AppConfig get config => _runtime.registry.get<AppConfig>();

  /// Whether the first-run onboarding flow (Milestone 6 Part B) still needs
  /// to be shown — `true` until the user completes it via Skip, Start
  /// Fresh, or Demo Mode (see [OnboardingStatusStore]).
  final bool needsOnboarding;

  /// Initialises the runtime and returns a fully booted [AppBootstrap].
  ///
  /// [financeStorageFile]/[tasksStorageFile], when supplied, are used as the
  /// Finance/Tasks persistence files instead of resolving them via
  /// `path_provider` — tests pass temporary files here so they never touch
  /// `path_provider`'s platform channel. [onboardingStatusFile] is the
  /// equivalent override for [OnboardingStatusStore].
  ///
  /// Throws [RuntimeException] (from `platform_runtime`) if any module fails
  /// to register, initialise, or start.
  static Future<AppBootstrap> boot({
    File? financeStorageFile,
    File? tasksStorageFile,
    File? habitsStorageFile,
    File? goalsStorageFile,
    File? notesStorageFile,
    File? calendarStorageFile,
    File? onboardingStatusFile,
  }) async {
    final financeExecutor = await FileBackedFinanceDatabaseExecutor.open(
      financeStorageFile ?? await _defaultFinanceStorageFile(),
    );
    final realFinanceRunner = FileBackedFinanceTransactionRunner(financeExecutor);

    final taskExecutor = await FileBackedTaskDatabaseExecutor.open(
      tasksStorageFile ?? await _defaultTasksStorageFile(),
    );
    final realTaskRunner = FileBackedTaskTransactionRunner(taskExecutor);

    final habitExecutor = await FileBackedHabitDatabaseExecutor.open(
      habitsStorageFile ?? await _defaultHabitsStorageFile(),
    );
    final realHabitRunner = FileBackedHabitTransactionRunner(habitExecutor);

    final goalExecutor = await FileBackedGoalDatabaseExecutor.open(
      goalsStorageFile ?? await _defaultGoalsStorageFile(),
    );
    final realGoalRunner = FileBackedGoalTransactionRunner(goalExecutor);

    final noteExecutor = await FileBackedNoteDatabaseExecutor.open(
      notesStorageFile ?? await _defaultNotesStorageFile(),
    );
    final realNoteRunner = FileBackedNoteTransactionRunner(noteExecutor);

    final calendarExecutor = await FileBackedEventDatabaseExecutor.open(
      calendarStorageFile ?? await _defaultCalendarStorageFile(),
    );
    final realCalendarRunner = FileBackedEventTransactionRunner(calendarExecutor);

    // The switchable pairs are what FinanceStorageModule/TasksStorageModule/
    // HabitsStorageModule actually bind — every Finance/Tasks/Habits
    // repository resolves these instances for the app's lifetime.
    // DemoModeController swaps each pair's internal delegate between its
    // real (file-backed) executor and a fresh in-memory demo one; nothing
    // downstream needs to know a swap ever happens (Milestone 6 Part A;
    // extended to Tasks in Milestone 7; extended to Habits thereafter).
    final switchableFinanceExecutor = SwitchableFinanceDatabaseExecutor(financeExecutor);
    final switchableFinanceRunner = SwitchableFinanceTransactionRunner(realFinanceRunner);
    final switchableTaskExecutor = SwitchableTaskDatabaseExecutor(taskExecutor);
    final switchableTaskRunner = SwitchableTaskTransactionRunner(realTaskRunner);
    final switchableHabitExecutor = SwitchableHabitDatabaseExecutor(habitExecutor);
    final switchableHabitRunner = SwitchableHabitTransactionRunner(realHabitRunner);
    final switchableGoalExecutor = SwitchableGoalDatabaseExecutor(goalExecutor);
    final switchableGoalRunner = SwitchableGoalTransactionRunner(realGoalRunner);
    final switchableNoteExecutor = SwitchableNoteDatabaseExecutor(noteExecutor);
    final switchableNoteRunner = SwitchableNoteTransactionRunner(realNoteRunner);
    final switchableCalendarExecutor = SwitchableEventDatabaseExecutor(calendarExecutor);
    final switchableCalendarRunner = SwitchableEventTransactionRunner(realCalendarRunner);
    final demoModeController = DemoModeController(
      financeExecutor: switchableFinanceExecutor,
      financeRunner: switchableFinanceRunner,
      realFinanceExecutor: financeExecutor,
      realFinanceRunner: realFinanceRunner,
      taskExecutor: switchableTaskExecutor,
      taskRunner: switchableTaskRunner,
      realTaskExecutor: taskExecutor,
      realTaskRunner: realTaskRunner,
      habitExecutor: switchableHabitExecutor,
      habitRunner: switchableHabitRunner,
      realHabitExecutor: habitExecutor,
      realHabitRunner: realHabitRunner,
      goalExecutor: switchableGoalExecutor,
      goalRunner: switchableGoalRunner,
      realGoalExecutor: goalExecutor,
      realGoalRunner: realGoalRunner,
      noteExecutor: switchableNoteExecutor,
      noteRunner: switchableNoteRunner,
      realNoteExecutor: noteExecutor,
      realNoteRunner: realNoteRunner,
      calendarExecutor: switchableCalendarExecutor,
      calendarRunner: switchableCalendarRunner,
      realCalendarExecutor: calendarExecutor,
      realCalendarRunner: realCalendarRunner,
      workspaceId: WorkspaceContext.defaultWorkspaceId,
    );

    final onboardingStore = OnboardingStatusStore(
      onboardingStatusFile ?? await _defaultOnboardingStatusFile(),
    );
    final needsOnboarding = !await onboardingStore.hasCompletedOnboarding();

    final runtime = RuntimeBootstrap()
      ..addModule(const AppModule())
      ..addModule(ApplicationModule())                          // registers core application singletons
      ..addModule(FinanceStorageModule(                          // binds Finance's persistence
        executor: switchableFinanceExecutor,
        runner: switchableFinanceRunner,
      ))
      ..addModule(const FinanceModule())                        // installs the Finance feature
      ..addModule(TasksStorageModule(                            // binds Tasks' persistence
        executor: switchableTaskExecutor,
        runner: switchableTaskRunner,
      ))
      ..addModule(const TasksModule())                          // installs the Tasks feature
      ..addModule(HabitsStorageModule(                           // binds Habits' persistence
        executor: switchableHabitExecutor,
        runner: switchableHabitRunner,
      ))
      ..addModule(const HabitsModule())                         // installs the Habits feature
      ..addModule(GoalsStorageModule(                            // binds Goals' persistence
        executor: switchableGoalExecutor,
        runner: switchableGoalRunner,
      ))
      ..addModule(const GoalsModule())                          // installs the Goals feature
      ..addModule(NotesStorageModule(                            // binds Notes' persistence
        executor: switchableNoteExecutor,
        runner: switchableNoteRunner,
      ))
      ..addModule(const NotesModule())                          // installs the Notes feature
      ..addModule(CalendarStorageModule(                         // binds Calendar's persistence
        executor: switchableCalendarExecutor,
        runner: switchableCalendarRunner,
      ))
      ..addModule(const CalendarModule())                       // installs the Calendar feature
      ..addModule(DemoModule(controller: demoModeController))    // Demo Mode management (Milestone 6)
      ..addModule(OnboardingModule(store: onboardingStore))      // first-run status (Milestone 6)
      ..addModule(const SampleModule());                        // validates Feature Framework

    await runtime.boot();

    // Run the Application Startup Pipeline so feature startup steps execute.
    final registry = runtime.registry;
    final logger = registry.get<ILogger>();

    await registry.get<StartupPipeline>().execute(
          StartupContext(
            locator: registry,
            config: registry.get<AppConfig>(),
          ),
        );

    logger.info('Runtime Started');
    logger.info('Application Started');
    logger.info(
      'Features loaded: ${registry.get<FeatureRegistry>().features.map((f) => f.id).join(', ')}',
    );

    return AppBootstrap._(runtimeBootstrap: runtime, needsOnboarding: needsOnboarding);
  }

  /// Shuts down the runtime gracefully.
  ///
  /// Logs "Application Closed", then calls [RuntimeBootstrap.shutdown] which
  /// invokes each module's [onStop] and [onDispose] hooks in reverse
  /// registration order.
  Future<void> shutdown() async {
    _runtime.registry.get<ILogger>().info('Application Closed');
    await _runtime.shutdown();
  }

  /// The production Finance storage file: `<app documents dir>/finance_data.json`.
  static Future<File> _defaultFinanceStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/finance_data.json');
  }

  /// The production Tasks storage file: `<app documents dir>/tasks_data.json`.
  static Future<File> _defaultTasksStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/tasks_data.json');
  }

  /// The production Habits storage file: `<app documents dir>/habits_data.json`.
  static Future<File> _defaultHabitsStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/habits_data.json');
  }

  /// The production Goals storage file: `<app documents dir>/goals_data.json`.
  static Future<File> _defaultGoalsStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/goals_data.json');
  }

  /// The production Notes storage file: `<app documents dir>/notes_data.json`.
  static Future<File> _defaultNotesStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/notes_data.json');
  }

  /// The production Calendar storage file: `<app documents dir>/calendar_data.json`.
  static Future<File> _defaultCalendarStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/calendar_data.json');
  }

  /// The production onboarding status file: `<app documents dir>/onboarding_status.json`.
  static Future<File> _defaultOnboardingStatusFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/onboarding_status.json');
  }
}
