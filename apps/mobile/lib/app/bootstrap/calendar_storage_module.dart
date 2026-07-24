import 'package:feature_calendar/calendar.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Binds the Calendar feature's persistence leaf interfaces
/// ([IEventDatabaseExecutor], [IEventTransactionRunner]) before
/// [CalendarModule] is registered. Mirrors `NotesStorageModule`/
/// `TasksStorageModule` exactly.
///
/// [executor]/[runner] are the app's *switchable* wrappers (see
/// `SwitchableEventDatabaseExecutor`/`SwitchableEventTransactionRunner`),
/// not the raw file-backed pair directly — every Calendar repository
/// resolves these same two instances for the app's lifetime, so
/// `DemoModeController` can swap their delegate between real and demo data
/// without any repository being re-created.
final class CalendarStorageModule extends RuntimeModule {
  const CalendarStorageModule({required this.executor, required this.runner});

  final IEventDatabaseExecutor executor;
  final IEventTransactionRunner runner;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar
      ..registerSingleton<IEventDatabaseExecutor>(executor)
      ..registerSingleton<IEventTransactionRunner>(runner);
  }
}
