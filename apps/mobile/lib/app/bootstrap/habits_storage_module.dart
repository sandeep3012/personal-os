import 'package:feature_habits/habits.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Binds the Habits feature's persistence leaf interfaces
/// ([IHabitDatabaseExecutor], [IHabitTransactionRunner]) before
/// [HabitsModule] is registered. Mirrors `TasksStorageModule`/
/// `FinanceStorageModule` exactly.
///
/// [executor]/[runner] are the app's *switchable* wrappers (see
/// `SwitchableHabitDatabaseExecutor`/`SwitchableHabitTransactionRunner`),
/// not the raw file-backed pair directly — every Habits repository resolves
/// these same two instances for the app's lifetime, so `DemoModeController`
/// can swap their delegate between real and demo data without any
/// repository being re-created.
final class HabitsStorageModule extends RuntimeModule {
  const HabitsStorageModule({required this.executor, required this.runner});

  final IHabitDatabaseExecutor executor;
  final IHabitTransactionRunner runner;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar
      ..registerSingleton<IHabitDatabaseExecutor>(executor)
      ..registerSingleton<IHabitTransactionRunner>(runner);
  }
}
