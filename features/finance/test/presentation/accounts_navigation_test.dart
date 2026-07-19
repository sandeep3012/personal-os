import 'package:application/application.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/di/finance_module.dart';
import 'package:feature_finance/src/presentation/pages/accounts_page.dart';
import 'package:feature_finance/src/presentation/routes/finance_routes.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_runtime/registry/service_registry.dart';

import '../data/dao/fake_finance_database_executor.dart';
import '../data/repositories/fake_finance_transaction_runner.dart';

/// Verifies AccountsPage is correctly wired into the existing
/// `/finance/accounts` route — no new route hierarchy is introduced. Actual
/// `go_router` navigation lives in `apps/mobile` (out of this package's
/// scope); these tests verify the platform-independent routing layer
/// (`RouteRegistry`/`ApplicationRouter`) that the app layer builds on.
void main() {
  late ServiceRegistry registry;

  setUp(() {
    registry = ServiceRegistry()
      ..registerSingleton<FeatureRegistry>(FeatureRegistry())
      ..registerSingleton<RouteRegistry>(RouteRegistry())
      ..registerSingleton<StartupPipeline>(StartupPipeline())
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

  group('Accounts route resolution', () {
    test('the /finance/accounts route is registered', () {
      final routeRegistry = registry.get<RouteRegistry>();
      expect(routeRegistry.containsPath(FinanceRoutes.accounts.path), isTrue);
      expect(
        routeRegistry.containsName(FinanceRoutes.accounts.name),
        isTrue,
      );
    });

    test('ApplicationRouter resolves the accounts route by path and name',
        () {
      final router = ApplicationRouter(registry: registry.get<RouteRegistry>());

      final byPath = router.resolveByPath('/finance/accounts');
      final byName = router.resolveByName('finance-accounts');

      expect(byPath, FinanceRoutes.accounts);
      expect(byName, FinanceRoutes.accounts);
      expect(byPath, byName);
    });

    test('resolving the accounts route does not introduce any additional '
        'Finance route beyond the four already registered in Step 3', () {
      expect(registry.get<RouteRegistry>().length, 4);
    });
  });

  group('AccountsViewModel resolves for the page the route points to', () {
    test('AccountsViewModel is resolvable from the same container that '
        'registered the accounts route', () {
      final viewModel = registry.get<AccountsViewModel>();
      expect(viewModel, isA<AccountsViewModel>());
    });

    test('the resolved ViewModel can construct AccountsPage (the widget the '
        'app layer maps /finance/accounts to)', () {
      final viewModel = registry.get<AccountsViewModel>();
      expect(
        () => AccountsPage(viewModel: viewModel),
        returnsNormally,
      );
    });
  });
}
