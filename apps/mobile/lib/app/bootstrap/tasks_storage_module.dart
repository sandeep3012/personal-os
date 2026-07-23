import 'package:feature_tasks/tasks.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Binds the Tasks feature's persistence leaf interfaces
/// ([ITaskDatabaseExecutor], [ITaskTransactionRunner]) before [TasksModule]
/// is registered. Mirrors `FinanceStorageModule` exactly.
///
/// [executor]/[runner] are the app's *switchable* wrappers (see
/// `SwitchableTaskDatabaseExecutor`/`SwitchableTaskTransactionRunner`), not
/// the raw file-backed pair directly — every Tasks repository resolves
/// these same two instances for the app's lifetime, so `DemoModeController`
/// can swap their delegate between real and demo data without any
/// repository being re-created.
final class TasksStorageModule extends RuntimeModule {
  const TasksStorageModule({required this.executor, required this.runner});

  final ITaskDatabaseExecutor executor;
  final ITaskTransactionRunner runner;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar
      ..registerSingleton<ITaskDatabaseExecutor>(executor)
      ..registerSingleton<ITaskTransactionRunner>(runner);
  }
}
