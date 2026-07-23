import 'package:feature_goals/goals.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Binds the Goals feature's persistence leaf interfaces
/// ([IGoalDatabaseExecutor], [IGoalTransactionRunner]) before
/// [GoalsModule] is registered. Mirrors `TasksStorageModule`/
/// `FinanceStorageModule` exactly.
///
/// [executor]/[runner] are the app's *switchable* wrappers (see
/// `SwitchableGoalDatabaseExecutor`/`SwitchableGoalTransactionRunner`),
/// not the raw file-backed pair directly — every Goals repository resolves
/// these same two instances for the app's lifetime, so `DemoModeController`
/// can swap their delegate between real and demo data without any
/// repository being re-created.
final class GoalsStorageModule extends RuntimeModule {
  const GoalsStorageModule({required this.executor, required this.runner});

  final IGoalDatabaseExecutor executor;
  final IGoalTransactionRunner runner;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar
      ..registerSingleton<IGoalDatabaseExecutor>(executor)
      ..registerSingleton<IGoalTransactionRunner>(runner);
  }
}
