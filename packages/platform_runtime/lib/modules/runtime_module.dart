import 'package:platform_core/di/i_module.dart';

/// Base class for all runtime modules.
///
/// A [RuntimeModule] packages a cohesive set of services — it registers them
/// during [register] and participates in the runtime lifecycle through the
/// async hooks below.
///
/// [RuntimeBootstrap] calls the hooks in this order:
///
/// ```
/// register(registrar)   // synchronous — set up DI bindings
///   └─ onInit()         // async — open connections, read config
///       └─ onStart()    // async — begin background work
///           │
///           │  (app is running)
///           │
///       onStop()        // async — graceful shutdown
///   └─ onDispose()      // async — release resources
/// ```
///
/// Override only the hooks you need; defaults are all no-ops.
///
/// Example:
/// ```dart
/// class DatabaseModule extends RuntimeModule {
///   @override
///   void register(IDependencyRegistrar registrar) {
///     registrar.registerLazySingleton<IDatabase>(() => SqliteDatabase());
///   }
///
///   @override
///   Future<void> onInit() async {
///     final db = // resolve from locator
///     await db.open();
///   }
///
///   @override
///   Future<void> onDispose() async {
///     final db = // resolve from locator
///     await db.close();
///   }
/// }
/// ```
abstract class RuntimeModule implements IModule {
  const RuntimeModule();

  /// Called by [RuntimeBootstrap] after all modules have been registered.
  ///
  /// Use this hook to perform async initialisation — opening database
  /// connections, loading configuration, etc. Services from other modules
  /// are accessible via the service locator at this point.
  Future<void> onInit() async {}

  /// Called by [RuntimeBootstrap] after [onInit] completes on all modules.
  ///
  /// Use this hook to start background tasks, timers, or streams.
  Future<void> onStart() async {}

  /// Called by [RuntimeBootstrap] during shutdown, before [onDispose].
  ///
  /// Use this hook to gracefully stop background work — cancel timers,
  /// drain queues, etc.
  Future<void> onStop() async {}

  /// Called by [RuntimeBootstrap] after [onStop] completes on all modules.
  ///
  /// Use this hook to release resources — close file handles, database
  /// connections, streams, etc.
  Future<void> onDispose() async {}
}
