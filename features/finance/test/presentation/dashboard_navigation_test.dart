import 'package:application/application.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/di/finance_module.dart';
import 'package:feature_finance/src/presentation/pages/finance_home_page.dart';
import 'package:feature_finance/src/presentation/routes/finance_routes.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

import '../data/dao/fake_finance_database_executor.dart';
import '../data/repositories/fake_finance_transaction_runner.dart';

/// Verifies FinanceHomePage (the Dashboard) is correctly wired into the
/// existing `/finance` root route — no new route hierarchy is introduced.
/// Actual `go_router` navigation lives in `apps/mobile` (out of this
/// package's scope); these tests verify the platform-independent routing
/// layer (`RouteRegistry`/`ApplicationRouter`) that the app layer builds on.
void main() {
  late ServiceRegistry registry;

  setUp(() {
    registry = ServiceRegistry()
      ..registerSingleton<FeatureRegistry>(FeatureRegistry())
      ..registerSingleton<RouteRegistry>(RouteRegistry())
      ..registerSingleton<StartupPipeline>(StartupPipeline())
      ..registerSingleton<IdGenerator>(const UuidGenerator())
      ..registerSingleton<WorkspaceContext>(
        WorkspaceContext(initialWorkspaceId: WorkspaceContext.defaultWorkspaceId),
      );

    final executor = FakeFinanceDatabaseExecutor();
    registry
      ..registerSingleton<IFinanceDatabaseExecutor>(executor)
      ..registerSingleton<IFinanceTransactionRunner>(
        FakeFinanceTransactionRunner(executor),
      );

    const FinanceModule().register(registry);
  });

  group('Dashboard (root) route resolution', () {
    test('the /finance route is registered', () {
      final routeRegistry = registry.get<RouteRegistry>();
      expect(routeRegistry.containsPath(FinanceRoutes.root.path), isTrue);
      expect(routeRegistry.containsName(FinanceRoutes.root.name), isTrue);
    });

    test('ApplicationRouter resolves the root route by path and name', () {
      final router = ApplicationRouter(registry: registry.get<RouteRegistry>());

      final byPath = router.resolveByPath('/finance');
      final byName = router.resolveByName('finance');

      expect(byPath, FinanceRoutes.root);
      expect(byName, FinanceRoutes.root);
      expect(byPath, byName);
    });

    test('resolving the root route does not introduce any additional '
        'Finance route beyond the four already registered', () {
      expect(registry.get<RouteRegistry>().length, 4);
    });
  });

  group('FinanceHomeViewModel resolves for the page the route points to', () {
    test('FinanceHomeViewModel is resolvable from the same container that '
        'registered the root route', () {
      final viewModel = registry.get<FinanceHomeViewModel>();
      expect(viewModel, isA<FinanceHomeViewModel>());
    });

    test('the resolved ViewModel can construct FinanceHomePage (the widget '
        'the app layer maps /finance to)', () {
      final viewModel = registry.get<FinanceHomeViewModel>();
      expect(
        () => FinanceHomePage(viewModel: viewModel),
        returnsNormally,
      );
    });
  });
}
