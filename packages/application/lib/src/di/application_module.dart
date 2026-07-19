import 'package:application/src/features/feature_registry.dart';
import 'package:application/src/navigation/application_router.dart';
import 'package:application/src/routing/route_registry.dart';
import 'package:application/src/startup/startup_pipeline.dart';
import 'package:application/src/workspace/workspace_context.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/event_bus/event_bus.dart';
import 'package:platform_runtime/event_bus/i_event_bus.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Registers all core application-layer services into the DI container.
///
/// Add [ApplicationModule] to [RuntimeBootstrap] **before** any
/// [FeatureModule]. Feature modules read [FeatureRegistry], [RouteRegistry],
/// and [StartupPipeline] from the service locator during their own [register]
/// phase — those singletons must already exist.
///
/// ## Services registered
///
/// | Type | Implementation | Notes |
/// |---|---|---|
/// | [IEventBus] | [EventBus] | Disposed on [onDispose] |
/// | [RouteRegistry] | Empty registry | Feature modules populate it |
/// | [ApplicationRouter] | Wraps [RouteRegistry] | Platform-independent resolver |
/// | [StartupPipeline] | Empty pipeline | Feature modules add steps |
/// | [FeatureRegistry] | Empty catalog | Feature modules register metadata |
/// | [WorkspaceContext] | Seeded with [WorkspaceContext.defaultWorkspaceId] | ADR-004 — feature ViewModels read/subscribe, never invent their own workspace id |
///
/// ## Example
///
/// ```dart
/// final bootstrap = RuntimeBootstrap()
///   ..addModule(AppModule())
///   ..addModule(ApplicationModule())   // ← must come before feature modules
///   ..addModule(FinanceModule())
///   ..addModule(TasksModule());
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
    final featureRegistry = FeatureRegistry();
    final workspaceContext = WorkspaceContext(
      initialWorkspaceId: WorkspaceContext.defaultWorkspaceId,
    );

    registrar.registerSingleton<IEventBus>(bus);
    registrar.registerSingleton<RouteRegistry>(routeRegistry);
    registrar.registerSingleton<ApplicationRouter>(router);
    registrar.registerSingleton<StartupPipeline>(pipeline);
    registrar.registerSingleton<FeatureRegistry>(featureRegistry);
    registrar.registerSingleton<WorkspaceContext>(workspaceContext);
  }

  @override
  Future<void> onDispose() async {
    _bus?.dispose();
    _bus = null;
  }
}
