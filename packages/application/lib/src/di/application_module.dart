import 'package:application/src/navigation/application_router.dart';
import 'package:application/src/routing/route_registry.dart';
import 'package:application/src/startup/startup_pipeline.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/event_bus/event_bus.dart';
import 'package:platform_runtime/event_bus/i_event_bus.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Registers all core application-layer services into the DI container.
///
/// Add [ApplicationModule] to [RuntimeBootstrap] before calling `boot()`.
/// The module registers:
///
/// | Type | Implementation |
/// |---|---|
/// | [IEventBus] | [EventBus] singleton (disposed on [onDispose]) |
/// | [RouteRegistry] | Empty registry, ready for feature modules to populate |
/// | [ApplicationRouter] | Wraps the registered [RouteRegistry] |
/// | [StartupPipeline] | Empty pipeline, ready for steps to be added |
///
/// ## Example
///
/// ```dart
/// final bootstrap = RuntimeBootstrap()
///   ..addModule(AppModule())
///   ..addModule(ApplicationModule());
///
/// await bootstrap.boot();
/// ```
final class ApplicationModule extends RuntimeModule {
  EventBus? _bus;

  @override
  void register(IDependencyRegistrar registrar) {
    final bus = EventBus();
    _bus = bus;

    final routeRegistry = RouteRegistry();
    final router = ApplicationRouter(registry: routeRegistry);
    final pipeline = StartupPipeline();

    registrar.registerSingleton<IEventBus>(bus);
    registrar.registerSingleton<RouteRegistry>(routeRegistry);
    registrar.registerSingleton<ApplicationRouter>(router);
    registrar.registerSingleton<StartupPipeline>(pipeline);
  }

  @override
  Future<void> onDispose() async {
    _bus?.dispose();
    _bus = null;
  }
}
