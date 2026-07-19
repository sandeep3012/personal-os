import 'package:application/application.dart';
import 'package:feature_finance/finance.dart';
import 'package:feature_finance/src/data/repositories/account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/bootstrap/runtime_bootstrap.dart';
import 'package:platform_runtime/bootstrap/runtime_exception.dart';

import '../data/dao/fake_finance_database_executor.dart';
import '../data/repositories/fake_finance_transaction_runner.dart';

/// A minimal stand-in for "some other, already-installed feature" — proves
/// Finance can be loaded into the same runtime as another feature module
/// without conflict, without this package depending on a real sibling
/// feature package (which DOC-031 §7 forbids: features never import each
/// other's packages).
final class _DummyOtherFeatureService {
  bool ping() => true;
}

final class _DummyOtherFeatureModule extends FeatureModule {
  const _DummyOtherFeatureModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'dummy-other-feature',
        name: 'Dummy Other Feature',
        version: '1.0.0',
      );

  @override
  void registerServices(IDependencyRegistrar registrar) {
    registrar.registerSingleton<_DummyOtherFeatureService>(
      _DummyOtherFeatureService(),
    );
  }
}

/// Verifies FinanceModule integrates correctly with the real
/// [RuntimeBootstrap]/[ApplicationModule] — the same orchestration classes
/// `apps/mobile`'s [AppBootstrap] uses in production. No UI, no routes, no
/// business behavior is exercised here — only that the runtime recognizes
/// and loads Finance as an installed feature.
void main() {
  group('RuntimeBootstrap — loading FinanceModule', () {
    test('boot() completes successfully with FinanceModule installed',
        () async {
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const FinanceModule());

      await runtime.boot();

      expect(runtime.isBooted, isTrue);
      await runtime.shutdown();
    });

    test('boot() succeeds even though no storage engine is registered yet',
        () async {
      // FinanceModule's persistence bindings are all lazy — nothing during
      // register()/onInit()/onStart() eagerly resolves
      // IFinanceDatabaseExecutor or IFinanceTransactionRunner, so the
      // runtime boots even before those (ADR-pending) interfaces have a
      // concrete implementation.
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const FinanceModule());

      await expectLater(runtime.boot(), completes);
      await runtime.shutdown();
    });

    test('FeatureRegistry contains the finance feature after boot', () async {
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const FinanceModule());
      await runtime.boot();

      final registry = runtime.registry.get<FeatureRegistry>();
      expect(registry.isRegistered('finance'), isTrue);

      final metadata = registry.find('finance')!;
      expect(metadata.id, 'finance');
      expect(metadata.name, 'Finance');
      expect(metadata.version, isNotEmpty);
      expect(metadata.description, isNotEmpty);

      await runtime.shutdown();
    });

    test('Finance registers its presentation-foundation routes', () async {
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const FinanceModule());
      await runtime.boot();

      // Sprint 8C Step 3 added FinanceModule.registerRoutes — this
      // superseded the "no routes yet" assumption from Step 2.
      final routeRegistry = runtime.registry.get<RouteRegistry>();
      expect(routeRegistry.routes, hasLength(4));
      expect(routeRegistry.containsPath('/finance'), isTrue);

      await runtime.shutdown();
    });

    test('Finance adds no startup steps yet', () async {
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const FinanceModule());
      await runtime.boot();

      // No assertion beyond "boot succeeded" is possible here without a
      // StartupPipeline introspection API; the absence of any Finance
      // startup step is structurally guaranteed by FinanceModule not
      // overriding `startupSteps` (defaults to the empty list).
      expect(runtime.isBooted, isTrue);

      await runtime.shutdown();
    });
  });

  group('RuntimeBootstrap — dependency graph remains valid at runtime scale',
      () {
    test('resolving a Finance repository succeeds once the storage engine '
        'stand-ins are supplied', () async {
      final runtime = RuntimeBootstrap()..addModule(ApplicationModule());

      // Seed the two ADR-pending leaf interfaces directly on the registry
      // before boot — the same substitution pattern used by
      // FinanceIntegrationContainer in the Sprint 8B integration tests.
      final executor = FakeFinanceDatabaseExecutor();
      runtime.registry
        ..registerSingleton<IFinanceDatabaseExecutor>(executor)
        ..registerSingleton<IFinanceTransactionRunner>(
          FakeFinanceTransactionRunner(executor),
        );

      runtime.addModule(const FinanceModule());
      await runtime.boot();

      final repo = runtime.registry.get<IAccountRepository>();
      expect(repo, isA<AccountRepository>());

      await runtime.shutdown();
    });

    test('resolving a Finance repository before the storage engine is '
        'supplied throws, by design', () async {
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const FinanceModule());
      await runtime.boot();

      expect(
        () => runtime.registry.get<IAccountRepository>(),
        throwsA(anything),
      );

      await runtime.shutdown();
    });
  });

  group('RuntimeBootstrap — duplicate module registration prevented', () {
    test('adding and booting FinanceModule twice throws RuntimeException',
        () async {
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const FinanceModule())
        ..addModule(const FinanceModule());

      await expectLater(
        runtime.boot(),
        throwsA(isA<RuntimeException>()),
      );
    });
  });

  group('RuntimeBootstrap — existing features unaffected', () {
    test('another feature module boots correctly alongside FinanceModule',
        () async {
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const FinanceModule())
        ..addModule(const _DummyOtherFeatureModule());

      await runtime.boot();

      final registry = runtime.registry.get<FeatureRegistry>();
      expect(registry.isRegistered('finance'), isTrue);
      expect(registry.isRegistered('dummy-other-feature'), isTrue);

      final otherService = runtime.registry.get<_DummyOtherFeatureService>();
      expect(otherService.ping(), isTrue);

      await runtime.shutdown();
    });

    test('module registration order does not affect either feature '
        'resolving correctly', () async {
      final runtime = RuntimeBootstrap()
        ..addModule(ApplicationModule())
        ..addModule(const _DummyOtherFeatureModule())
        ..addModule(const FinanceModule());

      await runtime.boot();

      expect(
        runtime.registry.get<FeatureRegistry>().isRegistered('finance'),
        isTrue,
      );
      expect(
        runtime.registry.isRegistered<_DummyOtherFeatureService>(),
        isTrue,
      );

      await runtime.shutdown();
    });
  });
}
