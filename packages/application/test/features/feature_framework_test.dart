import 'package:application/application.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:platform_runtime/modules/runtime_module.dart';
import 'package:platform_runtime/registry/service_registry.dart';
import 'package:test/test.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Minimal [FeatureModule] that registers nothing beyond mandatory metadata.
final class _MinimalModule extends FeatureModule {
  const _MinimalModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'minimal',
        name: 'Minimal',
        version: '1.0.0',
      );
}

/// [FeatureModule] that registers two routes and one startup step.
final class _FullModule extends FeatureModule {
  const _FullModule();

  static const _route1 = RouteDefinition(path: '/full', name: 'full');
  static const _route2 =
      RouteDefinition(path: '/full/detail', name: 'fullDetail');

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'full',
        name: 'Full Feature',
        version: '2.3.0',
        description: 'A fully configured feature.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(_route1);
    registry.register(_route2);
  }

  @override
  List<StartupStep> get startupSteps => [_RecordingStep('full-init')];

  @override
  void registerServices(IDependencyRegistrar registrar) {
    registrar.registerSingleton<_FakeService>(const _FakeService('full-svc'));
  }
}

/// A second feature module to test multi-feature registration.
final class _SecondModule extends FeatureModule {
  const _SecondModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'second',
        name: 'Second Feature',
        version: '0.1.0',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(const RouteDefinition(path: '/second', name: 'second'));
  }
}

/// Startup step that records its execution.
final class _RecordingStep implements StartupStep {
  _RecordingStep(this.name);

  @override
  final String name;

  bool executed = false;

  @override
  Future<void> execute(StartupContext context) async {
    executed = true;
  }
}

/// Trivial service used to verify DI registration.
final class _FakeService {
  const _FakeService(this.tag);
  final String tag;
}

/// Builds a [ServiceRegistry] with the core application singletons that
/// [FeatureModule.register] expects to find.
ServiceRegistry _makeRegistry() {
  final registry = ServiceRegistry();
  final appModule = ApplicationModule();
  appModule.register(registry);
  return registry;
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── FeatureMetadata ────────────────────────────────────────────────────────

  group('FeatureMetadata', () {
    test('stores id, name, version, and description', () {
      const m = FeatureMetadata(
        id: 'finance',
        name: 'Finance',
        version: '1.0.0',
        description: 'Expense tracking.',
      );
      expect(m.id, 'finance');
      expect(m.name, 'Finance');
      expect(m.version, '1.0.0');
      expect(m.description, 'Expense tracking.');
    });

    test('description defaults to empty string', () {
      const m = FeatureMetadata(id: 'x', name: 'X', version: '0.1.0');
      expect(m.description, '');
    });

    test('equality holds for identical values', () {
      const a = FeatureMetadata(id: 'a', name: 'A', version: '1.0.0');
      const b = FeatureMetadata(id: 'a', name: 'A', version: '1.0.0');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when id differs', () {
      const a = FeatureMetadata(id: 'a', name: 'X', version: '1.0.0');
      const b = FeatureMetadata(id: 'b', name: 'X', version: '1.0.0');
      expect(a, isNot(equals(b)));
    });

    test('inequality when name differs', () {
      const a = FeatureMetadata(id: 'x', name: 'Alpha', version: '1.0.0');
      const b = FeatureMetadata(id: 'x', name: 'Beta', version: '1.0.0');
      expect(a, isNot(equals(b)));
    });

    test('inequality when version differs', () {
      const a = FeatureMetadata(id: 'x', name: 'X', version: '1.0.0');
      const b = FeatureMetadata(id: 'x', name: 'X', version: '2.0.0');
      expect(a, isNot(equals(b)));
    });

    test('inequality when description differs', () {
      const a = FeatureMetadata(id: 'x', name: 'X', version: '1.0.0');
      const b = FeatureMetadata(
          id: 'x', name: 'X', version: '1.0.0', description: 'desc');
      expect(a, isNot(equals(b)));
    });

    test('toString contains id, name, and version', () {
      const m = FeatureMetadata(id: 'fin', name: 'Finance', version: '3.0.0');
      expect(m.toString(), contains('fin'));
      expect(m.toString(), contains('Finance'));
      expect(m.toString(), contains('3.0.0'));
    });
  });

  // ── FeatureRegistry ────────────────────────────────────────────────────────

  group('FeatureRegistry', () {
    late FeatureRegistry registry;

    setUp(() => registry = FeatureRegistry());

    test('is empty initially', () {
      expect(registry.isEmpty, isTrue);
      expect(registry.isNotEmpty, isFalse);
      expect(registry.length, 0);
      expect(registry.features, isEmpty);
    });

    test('register adds a feature', () {
      registry.register(
          const FeatureMetadata(id: 'fin', name: 'Finance', version: '1.0.0'));
      expect(registry.length, 1);
      expect(registry.isEmpty, isFalse);
      expect(registry.isNotEmpty, isTrue);
    });

    test('isRegistered returns true after register', () {
      registry.register(
          const FeatureMetadata(id: 'fin', name: 'Finance', version: '1.0.0'));
      expect(registry.isRegistered('fin'), isTrue);
    });

    test('isRegistered returns false for unknown id', () {
      expect(registry.isRegistered('unknown'), isFalse);
    });

    test('find returns metadata for known id', () {
      const m = FeatureMetadata(id: 'fin', name: 'Finance', version: '1.0.0');
      registry.register(m);
      expect(registry.find('fin'), equals(m));
    });

    test('find returns null for unknown id', () {
      expect(registry.find('unknown'), isNull);
    });

    test('register multiple features', () {
      registry.register(
          const FeatureMetadata(id: 'fin', name: 'Finance', version: '1.0.0'));
      registry.register(
          const FeatureMetadata(id: 'tasks', name: 'Tasks', version: '1.0.0'));
      expect(registry.length, 2);
    });

    test('duplicate id throws ArgumentError', () {
      registry.register(
          const FeatureMetadata(id: 'fin', name: 'Finance', version: '1.0.0'));
      expect(
        () => registry.register(const FeatureMetadata(
            id: 'fin', name: 'Finance v2', version: '2.0.0')),
        throwsArgumentError,
      );
    });

    test('features returns unmodifiable list', () {
      registry.register(
          const FeatureMetadata(id: 'fin', name: 'Finance', version: '1.0.0'));
      expect(() => registry.features.add(
            const FeatureMetadata(id: 'x', name: 'X', version: '1.0.0'),
          ), throwsUnsupportedError);
    });

    test('features returns all registered metadata', () {
      const m1 =
          FeatureMetadata(id: 'fin', name: 'Finance', version: '1.0.0');
      const m2 =
          FeatureMetadata(id: 'tasks', name: 'Tasks', version: '1.0.0');
      registry.register(m1);
      registry.register(m2);
      expect(registry.features, containsAll([m1, m2]));
    });
  });

  // ── FeatureException ───────────────────────────────────────────────────────

  group('FeatureException', () {
    test('stores message', () {
      const e = FeatureException(message: 'Feature not found');
      expect(e.message, 'Feature not found');
    });

    test('stores optional cause', () {
      final cause = Exception('underlying error');
      final e = FeatureException(message: 'msg', cause: cause);
      expect(e.cause, same(cause));
    });

    test('equality holds for same message and cause', () {
      const a = FeatureException(message: 'err');
      const b = FeatureException(message: 'err');
      expect(a, equals(b));
    });

    test('toString includes exception type and message', () {
      const e = FeatureException(message: 'broken');
      expect(e.toString(), contains('FeatureException'));
      expect(e.toString(), contains('broken'));
    });
  });

  // ── ApplicationModule — FeatureRegistry registration ──────────────────────

  group('ApplicationModule + FeatureRegistry', () {
    test('registers FeatureRegistry singleton', () {
      final registry = _makeRegistry();
      expect(registry.isRegistered<FeatureRegistry>(), isTrue);
    });

    test('FeatureRegistry is empty before any feature module runs', () {
      final registry = _makeRegistry();
      final fr = registry.get<FeatureRegistry>();
      expect(fr.isEmpty, isTrue);
    });
  });

  // ── ApplicationModule — WorkspaceContext registration (ADR-004) ───────────

  group('ApplicationModule + WorkspaceContext', () {
    test('registers a WorkspaceContext singleton', () {
      final registry = _makeRegistry();
      expect(registry.isRegistered<WorkspaceContext>(), isTrue);
    });

    test('seeds WorkspaceContext with WorkspaceContext.defaultWorkspaceId', () {
      final registry = _makeRegistry();
      expect(
        registry.get<WorkspaceContext>().workspaceId,
        WorkspaceContext.defaultWorkspaceId,
      );
    });

    test('the same WorkspaceContext instance is shared across resolutions',
        () {
      final registry = _makeRegistry();
      final first = registry.get<WorkspaceContext>();
      final second = registry.get<WorkspaceContext>();
      expect(identical(first, second), isTrue);
    });

    test('feature modules can resolve WorkspaceContext registered before '
        'them', () {
      final registry = _makeRegistry();
      const _MinimalModule().register(registry);
      expect(registry.isRegistered<WorkspaceContext>(), isTrue);
    });
  });

  // ── FeatureModule ──────────────────────────────────────────────────────────

  group('FeatureModule — minimal (no routes, no steps)', () {
    late ServiceRegistry registry;

    setUp(() {
      registry = _makeRegistry();
      const _MinimalModule().register(registry);
    });

    test('metadata is registered into FeatureRegistry', () {
      final fr = registry.get<FeatureRegistry>();
      expect(fr.isRegistered('minimal'), isTrue);
      expect(fr.find('minimal')?.name, 'Minimal');
    });

    test('no routes added to RouteRegistry', () {
      final rr = registry.get<RouteRegistry>();
      expect(rr.isEmpty, isTrue);
    });

    test('no steps added to StartupPipeline', () {
      final p = registry.get<StartupPipeline>();
      expect(p.steps, isEmpty);
    });
  });

  group('FeatureModule — full (routes, steps, services)', () {
    late ServiceRegistry registry;

    setUp(() {
      registry = _makeRegistry();
      const _FullModule().register(registry);
    });

    test('metadata is registered into FeatureRegistry', () {
      final fr = registry.get<FeatureRegistry>();
      expect(fr.isRegistered('full'), isTrue);
      expect(fr.find('full')?.description, 'A fully configured feature.');
    });

    test('routes are registered into RouteRegistry', () {
      final rr = registry.get<RouteRegistry>();
      expect(rr.containsPath('/full'), isTrue);
      expect(rr.containsPath('/full/detail'), isTrue);
    });

    test('startup steps are added to StartupPipeline', () {
      final p = registry.get<StartupPipeline>();
      expect(p.steps.length, 1);
      expect(p.steps.first.name, 'full-init');
    });

    test('services are registered via registerServices', () {
      expect(registry.isRegistered<_FakeService>(), isTrue);
      expect(registry.get<_FakeService>().tag, 'full-svc');
    });
  });

  group('FeatureModule — multiple features', () {
    late ServiceRegistry registry;

    setUp(() {
      registry = _makeRegistry();
      const _FullModule().register(registry);
      const _SecondModule().register(registry);
    });

    test('both features appear in FeatureRegistry', () {
      final fr = registry.get<FeatureRegistry>();
      expect(fr.length, 2);
      expect(fr.isRegistered('full'), isTrue);
      expect(fr.isRegistered('second'), isTrue);
    });

    test('routes from both features exist in RouteRegistry', () {
      final rr = registry.get<RouteRegistry>();
      expect(rr.containsPath('/full'), isTrue);
      expect(rr.containsPath('/second'), isTrue);
    });
  });

  group('FeatureModule — duplicate registration guard', () {
    test('duplicate feature id throws ArgumentError', () {
      final registry = _makeRegistry();
      const _MinimalModule().register(registry);
      expect(
        () => const _MinimalModule().register(registry),
        throwsArgumentError,
      );
    });
  });

  group('FeatureModule — startup pipeline execution', () {
    test('startup steps from FeatureModule execute via pipeline', () async {
      final registry = _makeRegistry();
      const _FullModule().register(registry);

      final pipeline = registry.get<StartupPipeline>();
      final step = pipeline.steps.first as _RecordingStep;
      expect(step.executed, isFalse);

      const config = AppConfig(
        appName: 'Test',
        environment: BuildEnvironment.development,
      );
      await pipeline.execute(
        StartupContext(locator: registry, config: config),
      );

      expect(step.executed, isTrue);
    });
  });

  // ── FeatureModule is a RuntimeModule ──────────────────────────────────────

  group('FeatureModule — RuntimeModule contract', () {
    test('is a RuntimeModule', () {
      expect(const _MinimalModule(), isA<RuntimeModule>());
    });

    test('onInit, onStart, onStop, onDispose are no-ops by default', () async {
      const module = _MinimalModule();
      await expectLater(module.onInit(), completes);
      await expectLater(module.onStart(), completes);
      await expectLater(module.onStop(), completes);
      await expectLater(module.onDispose(), completes);
    });
  });
}
