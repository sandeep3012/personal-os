import 'package:application/application.dart';
import 'package:feature_sample/sample.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:platform_runtime/registry/service_registry.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Builds a [ServiceRegistry] pre-populated with [ApplicationModule]
/// and [SampleModule], mirroring the real bootstrap order.
ServiceRegistry _makeRegistry() {
  final registry = ServiceRegistry();
  ApplicationModule().register(registry);
  const SampleModule().register(registry);
  return registry;
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── Feature registration ──────────────────────────────────────────────────

  group('SampleModule — feature registration', () {
    late ServiceRegistry registry;

    setUp(() => registry = _makeRegistry());

    test('sample feature appears in FeatureRegistry', () {
      final fr = registry.get<FeatureRegistry>();
      expect(fr.isRegistered('sample'), isTrue);
    });

    test('FeatureMetadata contains correct id, name, version', () {
      final meta = registry.get<FeatureRegistry>().find('sample')!;
      expect(meta.id, 'sample');
      expect(meta.name, 'Sample');
      expect(meta.version, '0.1.0');
    });

    test('FeatureMetadata description is non-empty', () {
      final meta = registry.get<FeatureRegistry>().find('sample')!;
      expect(meta.description, isNotEmpty);
    });
  });

  // ── Route registration ────────────────────────────────────────────────────

  group('SampleModule — route registration', () {
    late ServiceRegistry registry;

    setUp(() => registry = _makeRegistry());

    test('/sample path is registered in RouteRegistry', () {
      final rr = registry.get<RouteRegistry>();
      expect(rr.containsPath('/sample'), isTrue);
    });

    test('sample route name is registered in RouteRegistry', () {
      final rr = registry.get<RouteRegistry>();
      expect(rr.containsName('sample'), isTrue);
    });

    test('route can be resolved by path', () {
      final rr = registry.get<RouteRegistry>();
      final route = rr.findByPath('/sample');
      expect(route, isNotNull);
      expect(route!.name, 'sample');
    });
  });

  // ── StartupPipeline integration ───────────────────────────────────────────

  group('SampleModule — startup pipeline', () {
    late ServiceRegistry registry;

    setUp(() => registry = _makeRegistry());

    test('one startup step is added to StartupPipeline', () {
      final pipeline = registry.get<StartupPipeline>();
      expect(pipeline.steps.length, 1);
    });

    test('startup step is named sample-init', () {
      final step = registry.get<StartupPipeline>().steps.first;
      expect(step.name, 'sample-init');
    });

    test('startup step execution marks SampleService as loaded', () async {
      const config = AppConfig(
        appName: 'Test',
        environment: BuildEnvironment.development,
      );
      await registry.get<StartupPipeline>().execute(
            StartupContext(locator: registry, config: config),
          );
      expect(registry.get<SampleService>().isLoaded, isTrue);
    });

    test('status message after startup reports success', () async {
      const config = AppConfig(
        appName: 'Test',
        environment: BuildEnvironment.development,
      );
      await registry.get<StartupPipeline>().execute(
            StartupContext(locator: registry, config: config),
          );
      expect(
        registry.get<SampleService>().status,
        contains('Sample Feature Loaded Successfully'),
      );
    });
  });

  // ── DI registration ───────────────────────────────────────────────────────

  group('SampleModule — DI registration', () {
    late ServiceRegistry registry;

    setUp(() => registry = _makeRegistry());

    test('SampleService is registered', () {
      expect(registry.isRegistered<SampleService>(), isTrue);
    });

    test('GetSampleStatusUseCase is resolvable', () {
      expect(
        () => registry.get<GetSampleStatusUseCase>(),
        returnsNormally,
      );
    });

    test('GetSampleStatusUseCase produces new instance per call (factory)', () {
      final a = registry.get<GetSampleStatusUseCase>();
      final b = registry.get<GetSampleStatusUseCase>();
      expect(identical(a, b), isFalse);
    });

    test('SampleService is the same instance every call (singleton)', () {
      final a = registry.get<SampleService>();
      final b = registry.get<SampleService>();
      expect(identical(a, b), isTrue);
    });
  });

  // ── End-to-end: use case via DI ───────────────────────────────────────────

  group('SampleModule — use case end-to-end', () {
    test('use case returns initializing status before startup', () async {
      final registry = _makeRegistry();
      final uc = registry.get<GetSampleStatusUseCase>();
      final result = await uc.execute();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNot(contains('Successfully')));
    });

    test('use case returns success message after startup step runs', () async {
      final registry = _makeRegistry();
      const config = AppConfig(
        appName: 'Test',
        environment: BuildEnvironment.development,
      );
      await registry.get<StartupPipeline>().execute(
            StartupContext(locator: registry, config: config),
          );
      final result = await registry.get<GetSampleStatusUseCase>().execute();
      expect(result.valueOrNull, contains('Sample Feature Loaded Successfully'));
    });
  });

  // ── SampleModule is a RuntimeModule ──────────────────────────────────────

  group('SampleModule — RuntimeModule contract', () {
    test('lifecycle hooks are no-ops', () async {
      const module = SampleModule();
      await expectLater(module.onInit(), completes);
      await expectLater(module.onStart(), completes);
      await expectLater(module.onStop(), completes);
      await expectLater(module.onDispose(), completes);
    });
  });

  // ── SampleRoutes constants ────────────────────────────────────────────────

  group('SampleRoutes', () {
    test('root path is /sample', () {
      expect(SampleRoutes.root.path, '/sample');
    });

    test('root name is sample', () {
      expect(SampleRoutes.root.name, 'sample');
    });
  });
}
