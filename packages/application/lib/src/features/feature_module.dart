import 'package:application/src/features/feature_metadata.dart';
import 'package:application/src/features/feature_registry.dart';
import 'package:application/src/routing/route_registry.dart';
import 'package:application/src/startup/startup_pipeline.dart';
import 'package:application/src/startup/startup_step.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Base class for all Personal OS feature modules.
///
/// Each feature package creates one concrete subclass and adds it to
/// [RuntimeBootstrap] before calling `boot()`. The framework then:
///
/// 1. Registers the feature's [metadata] into [FeatureRegistry] (discovery).
/// 2. Calls [registerRoutes] so the feature can add its [RouteDefinition]s
///    to the shared [RouteRegistry] (synchronous — ADR-003 Section 5).
/// 3. Adds every step returned by [startupSteps] to the [StartupPipeline]
///    (runs after boot via the application startup tier).
/// 4. Calls [registerServices] so the feature can bind its own services.
///
/// ## Minimum implementation
///
/// ```dart
/// final class FinanceModule extends FeatureModule {
///   const FinanceModule();
///
///   @override
///   FeatureMetadata get metadata => const FeatureMetadata(
///     id: 'finance',
///     name: 'Finance',
///     version: '1.0.0',
///   );
///
///   @override
///   void registerRoutes(RouteRegistry registry) {
///     registry.register(FinanceRoutes.root);
///     registry.register(FinanceRoutes.accounts);
///   }
///
///   @override
///   void registerServices(IDependencyRegistrar registrar) {
///     registrar.registerLazySingleton<IAccountRepository>(
///       () => AccountRepository(registrar.get<IDatabase>()),
///     );
///   }
/// }
/// ```
///
/// ## Ordering constraint
///
/// [ApplicationModule] **must** be added to [RuntimeBootstrap] before any
/// [FeatureModule], because [register] reads [FeatureRegistry], [RouteRegistry],
/// and [StartupPipeline] from the service locator — and those are registered by
/// [ApplicationModule].
///
/// ## Do not override [register] directly
///
/// Override [registerServices], [registerRoutes], and [startupSteps] instead.
/// The [register] implementation handles framework wiring automatically.
abstract class FeatureModule extends RuntimeModule {
  const FeatureModule();

  /// Identity record for this feature.
  FeatureMetadata get metadata;

  /// Override to register feature-specific DI bindings.
  ///
  /// Called after routes and startup steps have been registered, so
  /// framework singletons are already available via the service locator.
  void registerServices(IDependencyRegistrar registrar) {}

  /// Override to register this feature's routes into [registry].
  ///
  /// Registration is synchronous (ADR-003 Section 5 — no conditional routes
  /// until a future ADR approves async registration).
  void registerRoutes(RouteRegistry registry) {}

  /// Override to supply startup steps for the [StartupPipeline].
  ///
  /// Steps are added in list order during [register] and executed
  /// sequentially by the Application Startup Pipeline after boot.
  List<StartupStep> get startupSteps => const [];

  /// Wires this feature into the Personal OS runtime.
  ///
  /// Do not override this method — override [registerServices],
  /// [registerRoutes], and [startupSteps] instead.
  ///
  /// The registrar passed by [RuntimeBootstrap] is always a [ServiceRegistry],
  /// which implements both [IDependencyRegistrar] and [IServiceLocator]. The
  /// cast below is safe within the Personal OS runtime contract.
  @override
  void register(IDependencyRegistrar registrar) {
    // ServiceRegistry (platform_runtime) implements both IDependencyRegistrar
    // and IServiceLocator. This cast is valid for all Personal OS runtimes.
    // A test helper that only implements IDependencyRegistrar will fail here
    // with a clear error — use a real ServiceRegistry in feature module tests.
    final locator = registrar as IServiceLocator;

    // 1. Feature discovery — catalog this feature.
    locator.get<FeatureRegistry>().register(metadata);

    // 2. Route registration — synchronous (ADR-003 Section 5).
    registerRoutes(locator.get<RouteRegistry>());

    // 3. Startup pipeline — add feature startup tasks.
    final pipeline = locator.get<StartupPipeline>();
    for (final step in startupSteps) {
      pipeline.addStep(step);
    }

    // 4. DI bindings — feature-specific services.
    registerServices(registrar);
  }
}
