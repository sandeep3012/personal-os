import 'package:application/application.dart';
import 'package:feature_sample/src/application/sample_service.dart';
import 'package:feature_sample/src/domain/use_cases/get_sample_status_use_case.dart';
import 'package:feature_sample/src/routes/sample_routes.dart';
import 'package:feature_sample/src/startup/sample_startup_step.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';

/// Feature module for the Sample reference feature.
///
/// This module exercises every [FeatureModule] extension point:
///
/// | Hook | What it does |
/// |---|---|
/// | [metadata] | Identifies the feature in [FeatureRegistry] |
/// | [registerRoutes] | Adds [SampleRoutes.root] to [RouteRegistry] |
/// | [startupSteps] | Adds [SampleStartupStep] to [StartupPipeline] |
/// | [registerServices] | Registers [SampleService] and [GetSampleStatusUseCase] |
///
/// ## Registration order
///
/// [ApplicationModule] must be added to [RuntimeBootstrap] **before**
/// [SampleModule]. The [FeatureModule.register] implementation reads
/// [FeatureRegistry], [RouteRegistry], and [StartupPipeline] from the DI
/// container — those must exist first.
///
/// ```dart
/// final bootstrap = RuntimeBootstrap()
///   ..addModule(AppModule())
///   ..addModule(ApplicationModule())  // ← first
///   ..addModule(const SampleModule()); // ← after
///
/// await bootstrap.boot();
/// ```
final class SampleModule extends FeatureModule {
  const SampleModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'sample',
        name: 'Sample',
        version: '0.1.0',
        description:
            'Reference implementation for Feature Framework validation. '
            'Not a business feature.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(SampleRoutes.root);
  }

  @override
  List<StartupStep> get startupSteps => [SampleStartupStep()];

  @override
  void registerServices(IDependencyRegistrar registrar) {
    final service = SampleService();
    registrar.registerSingleton<SampleService>(service);
    registrar.registerFactory<GetSampleStatusUseCase>(
      () => GetSampleStatusUseCase(service),
    );
  }
}
