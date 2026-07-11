import 'package:platform_runtime/bootstrap/runtime_exception.dart';
import 'package:platform_runtime/modules/runtime_module.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Orchestrates the startup and shutdown of the application runtime.
///
/// ## Lifecycle
///
/// ```
/// addModule(…)   // register modules before boot
/// boot()         // register → onInit → onStart (in registration order)
///   │
///   │  (app is running)
///   │
/// shutdown()     // onStop → onDispose (in reverse-registration order)
/// ```
///
/// [boot] and [shutdown] are idempotent — calling them more than once throws
/// a [RuntimeException] to prevent accidental double-initialisation.
///
/// ## Example
///
/// ```dart
/// final bootstrap = RuntimeBootstrap();
/// bootstrap
///   ..addModule(DatabaseModule())
///   ..addModule(AnalyticsModule());
///
/// await bootstrap.boot();
/// // … app is running …
/// await bootstrap.shutdown();
/// ```
final class RuntimeBootstrap {
  final _modules = <RuntimeModule>[];
  final _registry = ServiceRegistry();
  bool _booted = false;
  bool _shutdown = false;

  /// Read-only view of the service registry, available after [boot].
  ServiceRegistry get registry => _registry;

  /// Whether [boot] has completed successfully.
  bool get isBooted => _booted;

  /// Whether [shutdown] has completed successfully.
  bool get isShutdown => _shutdown;

  /// Adds [module] to the boot sequence.
  ///
  /// Must be called before [boot]. Throws [RuntimeException] if [boot] has
  /// already been called.
  void addModule(RuntimeModule module) {
    if (_booted) {
      throw const RuntimeException(
        message: 'Cannot add a module after boot() has been called.',
      );
    }
    _modules.add(module);
  }

  /// Runs the full startup sequence:
  ///
  /// 1. Calls [RuntimeModule.register] on every module (synchronous, in order).
  /// 2. Calls [RuntimeModule.onInit] on every module (async, in order).
  /// 3. Calls [RuntimeModule.onStart] on every module (async, in order).
  ///
  /// Throws [RuntimeException] if [boot] is called more than once.
  /// Wraps any exception thrown by a module hook in a [RuntimeException].
  Future<void> boot() async {
    if (_booted) {
      throw const RuntimeException(
        message: 'boot() has already been called. '
            'Create a new RuntimeBootstrap instance to restart.',
      );
    }

    // 1. Synchronous registration — every module gets a chance to bind
    //    its types before any async work starts.
    for (final module in _modules) {
      try {
        module.register(_registry);
      } catch (e, st) {
        throw RuntimeException(
          message: 'Module ${module.runtimeType} failed during register(): $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    // 2. Async init — open connections, read config, etc.
    for (final module in _modules) {
      try {
        await module.onInit();
      } catch (e, st) {
        throw RuntimeException(
          message: 'Module ${module.runtimeType} failed during onInit(): $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    // 3. Async start — begin background work.
    for (final module in _modules) {
      try {
        await module.onStart();
      } catch (e, st) {
        throw RuntimeException(
          message: 'Module ${module.runtimeType} failed during onStart(): $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    _booted = true;
  }

  /// Runs the full shutdown sequence in **reverse** registration order:
  ///
  /// 1. Calls [RuntimeModule.onStop] on every module.
  /// 2. Calls [RuntimeModule.onDispose] on every module.
  ///
  /// Throws [RuntimeException] if called before [boot] or more than once.
  /// Wraps any exception thrown by a module hook in a [RuntimeException].
  Future<void> shutdown() async {
    if (!_booted) {
      throw const RuntimeException(
        message: 'Cannot shut down before boot() has been called.',
      );
    }
    if (_shutdown) {
      throw const RuntimeException(
        message: 'shutdown() has already been called.',
      );
    }

    final reversed = _modules.reversed.toList();

    // 1. Graceful stop — cancel background work.
    for (final module in reversed) {
      try {
        await module.onStop();
      } catch (e, st) {
        throw RuntimeException(
          message: 'Module ${module.runtimeType} failed during onStop(): $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    // 2. Dispose — release resources.
    for (final module in reversed) {
      try {
        await module.onDispose();
      } catch (e, st) {
        throw RuntimeException(
          message: 'Module ${module.runtimeType} failed during onDispose(): $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    _shutdown = true;
  }
}
