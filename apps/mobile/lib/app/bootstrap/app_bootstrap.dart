import 'package:application/application.dart';
import 'package:feature_sample/sample.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/logging/i_logger.dart';
import 'package:platform_runtime/bootstrap/runtime_bootstrap.dart';
import 'package:personal_os/app/bootstrap/app_module.dart';

/// Orchestrates the Personal OS application startup and shutdown.
///
/// [AppBootstrap] is the single composition root for the application. It
/// creates the [RuntimeBootstrap], registers all modules in the correct order,
/// boots the runtime, and exposes the resulting service registry.
///
/// ## Module registration order (required)
///
/// ```
/// AppModule            — ILogger, AppConfig
/// ApplicationModule    — IEventBus, RouteRegistry, ApplicationRouter,
///                        StartupPipeline, FeatureRegistry
/// SampleModule         — SampleService, route /sample, SampleStartupStep
/// ```
///
/// [ApplicationModule] **must** precede all [FeatureModule]s so that
/// [FeatureRegistry], [RouteRegistry], and [StartupPipeline] exist in the
/// DI container when feature modules call [FeatureModule.register].
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
  AppBootstrap._({required RuntimeBootstrap runtimeBootstrap})
      : _runtime = runtimeBootstrap;

  final RuntimeBootstrap _runtime;

  /// Read-only view of all registered services, available after [boot].
  IServiceLocator get registry => _runtime.registry;

  /// Whether [boot] has completed.
  bool get isBooted => _runtime.isBooted;

  /// Whether [shutdown] has completed.
  bool get isShutdown => _runtime.isShutdown;

  /// Convenience accessor for [AppConfig] registered by [AppModule].
  AppConfig get config => _runtime.registry.get<AppConfig>();

  /// Initialises the runtime and returns a fully booted [AppBootstrap].
  ///
  /// Throws [RuntimeException] (from `platform_runtime`) if any module fails
  /// to register, initialise, or start.
  static Future<AppBootstrap> boot() async {
    final runtime = RuntimeBootstrap()
      ..addModule(const AppModule())
      ..addModule(ApplicationModule())       // registers core application singletons
      ..addModule(const SampleModule());     // validates Feature Framework

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
}
