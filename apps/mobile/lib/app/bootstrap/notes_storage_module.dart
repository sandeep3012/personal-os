import 'package:feature_notes/notes.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Binds the Notes feature's persistence leaf interfaces
/// ([INoteDatabaseExecutor], [INoteTransactionRunner]) before
/// [NotesModule] is registered. Mirrors `TasksStorageModule`/
/// `FinanceStorageModule` exactly.
///
/// [executor]/[runner] are the app's *switchable* wrappers (see
/// `SwitchableNoteDatabaseExecutor`/`SwitchableNoteTransactionRunner`),
/// not the raw file-backed pair directly — every Notes repository resolves
/// these same two instances for the app's lifetime, so `DemoModeController`
/// can swap their delegate between real and demo data without any
/// repository being re-created.
final class NotesStorageModule extends RuntimeModule {
  const NotesStorageModule({required this.executor, required this.runner});

  final INoteDatabaseExecutor executor;
  final INoteTransactionRunner runner;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar
      ..registerSingleton<INoteDatabaseExecutor>(executor)
      ..registerSingleton<INoteTransactionRunner>(runner);
  }
}
