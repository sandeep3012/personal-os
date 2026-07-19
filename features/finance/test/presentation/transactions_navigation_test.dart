import 'package:application/application.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/di/finance_module.dart';
import 'package:feature_finance/src/presentation/pages/transactions_page.dart';
import 'package:feature_finance/src/presentation/routes/finance_routes.dart';
import 'package:feature_finance/src/presentation/viewmodels/transactions_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_runtime/registry/service_registry.dart';

import '../data/dao/fake_finance_database_executor.dart';
import '../data/repositories/fake_finance_transaction_runner.dart';

/// Mirrors accounts_navigation_test.dart: verifies TransactionsPage is
/// wired into the existing `/finance/transactions` route (unchanged since
/// Sprint 8C Step 3) — no new route hierarchy is introduced for Transfers,
/// which are folded into the same page.
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

  group('Transactions route resolution', () {
    test('the /finance/transactions route is registered', () {
      final routeRegistry = registry.get<RouteRegistry>();
      expect(
        routeRegistry.containsPath(FinanceRoutes.transactions.path),
        isTrue,
      );
      expect(
        routeRegistry.containsName(FinanceRoutes.transactions.name),
        isTrue,
      );
    });

    test('ApplicationRouter resolves the transactions route by path and name',
        () {
      final router = ApplicationRouter(registry: registry.get<RouteRegistry>());

      final byPath = router.resolveByPath('/finance/transactions');
      final byName = router.resolveByName('finance-transactions');

      expect(byPath, FinanceRoutes.transactions);
      expect(byName, FinanceRoutes.transactions);
    });

    test('no new route hierarchy was introduced for Transfers — still '
        'exactly four Finance routes', () {
      expect(registry.get<RouteRegistry>().length, 4);
    });
  });

  group('TransactionsViewModel resolves for the page the route points to',
      () {
    test('TransactionsViewModel is resolvable from the same container that '
        'registered the transactions route', () {
      final viewModel = registry.get<TransactionsViewModel>();
      expect(viewModel, isA<TransactionsViewModel>());
    });

    test('the resolved ViewModel can construct TransactionsPage', () {
      final viewModel = registry.get<TransactionsViewModel>();
      expect(
        () => TransactionsPage(viewModel: viewModel),
        returnsNormally,
      );
    });
  });
}
