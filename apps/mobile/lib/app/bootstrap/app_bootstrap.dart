import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/logging/i_logger.dart';
import 'package:platform_runtime/bootstrap/runtime_bootstrap.dart';
import 'package:personal_os/app/bootstrap/app_module.dart';

/// Orchestrates the Personal OS application startup and shutdown.
///
/// [AppBootstrap] is the single entry-point for initialising the platform
/// layer. It creates a [RuntimeBootstrap], registers all application modules,
/// boots the runtime, and exposes the resulting service registry.
///
/// ## Startup sequence
///
/// ```
/// AppBootstrap.boot()
///   └─ RuntimeBootstrap.boot()
///       ├─ AppModule.register()   — bind ILogger, AppConfig
///       ├─ AppModule.onInit()     — no-op for shell sprint
///       └─ AppModule.onStart()    — no-op for shell sprint
///   └─ log "Application Started"
/// ```
///
/// ## Shutdown sequence
///
/// ```
/// AppBootstrap.shutdown()
///   └─ log "Application Closed"
///   └─ RuntimeBootstrap.shutdown()
///       └─ AppModule.onStop()     — no-op
///       └─ AppModule.onDispose()  — no-op
/// ```
final class AppBootstrap {
  AppBootstrap._({required RuntimeBootstrap runtimeBootstrap})
      : _runtime = runtimeBootstrap;

  final RuntimeBootstrap _runtime;

  /// Read-only view of all registered services.
  IServiceLocator get registry => _runtime.registry;

  /// Whether [boot] has completed.
  bool get isBooted => _runtime.isBooted;

  /// Whether [shutdown] has completed.
  bool get isShutdown => _runtime.isShutdown;

  /// Initialises the runtime and returns a fully booted [AppBootstrap].
  ///
  /// Throws [RuntimeException] (from `platform_runtime`) if any module fails
  /// to register, initialise, or start.
  static Future<AppBootstrap> boot() async {
    final runtime = RuntimeBootstrap()..addModule(const AppModule());
    await runtime.boot();

    final logger = runtime.registry.get<ILogger>();
    logger.info('Runtime Started');
    logger.info('Application Started');

    return AppBootstrap._(runtimeBootstrap: runtime);
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

  /// Convenience accessor for the [AppConfig] registered by [AppModule].
  AppConfig get config => _runtime.registry.get<AppConfig>();
}
