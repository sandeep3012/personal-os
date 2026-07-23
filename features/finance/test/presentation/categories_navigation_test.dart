import 'package:application/application.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/di/finance_module.dart';
import 'package:feature_finance/src/presentation/pages/categories_page.dart';
import 'package:feature_finance/src/presentation/routes/finance_routes.dart';
import 'package:feature_finance/src/presentation/viewmodels/categories_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

import '../data/dao/fake_finance_database_executor.dart';
import '../data/repositories/fake_finance_transaction_runner.dart';

/// Verifies CategoriesPage is correctly wired into the existing
/// `/finance/categories` route — no new route hierarchy is introduced.
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

  group('Categories route resolution', () {
    test('the /finance/categories route is registered', () {
      final routeRegistry = registry.get<RouteRegistry>();
      expect(routeRegistry.containsPath(FinanceRoutes.categories.path), isTrue);
      expect(
        routeRegistry.containsName(FinanceRoutes.categories.name),
        isTrue,
      );
    });

    test('ApplicationRouter resolves the categories route by path and name',
        () {
      final router = ApplicationRouter(registry: registry.get<RouteRegistry>());

      final byPath = router.resolveByPath('/finance/categories');
      final byName = router.resolveByName('finance-categories');

      expect(byPath, FinanceRoutes.categories);
      expect(byName, FinanceRoutes.categories);
      expect(byPath, byName);
    });

    test('resolving the categories route does not introduce any additional '
        'Finance route beyond the four already registered', () {
      expect(registry.get<RouteRegistry>().length, 4);
    });
  });

  group('CategoriesViewModel resolves for the page the route points to', () {
    test('CategoriesViewModel is resolvable from the same container that '
        'registered the categories route', () {
      final viewModel = registry.get<CategoriesViewModel>();
      expect(viewModel, isA<CategoriesViewModel>());
    });

    test('the resolved ViewModel can construct CategoriesPage (the widget '
        'the app layer maps /finance/categories to)', () {
      final viewModel = registry.get<CategoriesViewModel>();
      expect(
        () => CategoriesPage(viewModel: viewModel),
        returnsNormally,
      );
    });
  });
}
