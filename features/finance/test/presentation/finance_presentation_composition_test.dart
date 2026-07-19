import 'package:application/application.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/di/finance_module.dart';
import 'package:feature_finance/src/presentation/pages/accounts_page.dart';
import 'package:feature_finance/src/presentation/pages/categories_page.dart';
import 'package:feature_finance/src/presentation/pages/finance_home_page.dart';
import 'package:feature_finance/src/presentation/pages/transactions_page.dart';
import 'package:feature_finance/src/presentation/routes/finance_routes.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/categories_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_home_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/transactions_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_runtime/registry/service_registry.dart';

import '../data/dao/fake_finance_database_executor.dart';
import '../data/repositories/fake_finance_transaction_runner.dart';

/// Seeds the two leaf interfaces with no production implementation yet
/// (same pattern used throughout the DI/integration test suites), plus a
/// [WorkspaceContext] — normally registered by `ApplicationModule`
/// (ADR-004), but these tests build a registry manually rather than via a
/// real `ApplicationModule`.
void _seedStorageStandIns(ServiceRegistry registry) {
  final executor = FakeFinanceDatabaseExecutor();
  registry
    ..registerSingleton<IFinanceDatabaseExecutor>(executor)
    ..registerSingleton<IFinanceTransactionRunner>(
      FakeFinanceTransactionRunner(executor),
    )
    ..registerSingleton<WorkspaceContext>(
      WorkspaceContext(initialWorkspaceId: WorkspaceContext.defaultWorkspaceId),
    );
}

/// Verifies the Finance presentation foundation composes correctly: routes
/// register, ViewModels resolve from DI, and pages construct successfully.
/// No UI behavior (rendering, interaction) is tested here — that is
/// explicitly out of scope for this step.
void main() {
  group('FinanceRoutes — metadata', () {
    test('root, accounts, transactions, and categories are distinct paths',
        () {
      final paths = {
        FinanceRoutes.root.path,
        FinanceRoutes.accounts.path,
        FinanceRoutes.transactions.path,
        FinanceRoutes.categories.path,
      };
      expect(paths, hasLength(4));
    });

    test('root, accounts, transactions, and categories are distinct names',
        () {
      final names = {
        FinanceRoutes.root.name,
        FinanceRoutes.accounts.name,
        FinanceRoutes.transactions.name,
        FinanceRoutes.categories.name,
      };
      expect(names, hasLength(4));
    });

    test('every route path is non-empty and starts with /finance', () {
      for (final route in [
        FinanceRoutes.root,
        FinanceRoutes.accounts,
        FinanceRoutes.transactions,
        FinanceRoutes.categories,
      ]) {
        expect(route.path, isNotEmpty);
        expect(route.path, startsWith('/finance'));
        expect(route.name, isNotEmpty);
      }
    });
  });

  group('FinanceModule.registerRoutes', () {
    late ServiceRegistry registry;

    setUp(() {
      registry = ServiceRegistry()
        ..registerSingleton<FeatureRegistry>(FeatureRegistry())
        ..registerSingleton<RouteRegistry>(RouteRegistry())
        ..registerSingleton<StartupPipeline>(StartupPipeline());
    });

    test('registers all four Finance routes into RouteRegistry', () {
      const FinanceModule().register(registry);

      final routeRegistry = registry.get<RouteRegistry>();
      expect(routeRegistry.containsPath(FinanceRoutes.root.path), isTrue);
      expect(routeRegistry.containsPath(FinanceRoutes.accounts.path), isTrue);
      expect(
        routeRegistry.containsPath(FinanceRoutes.transactions.path),
        isTrue,
      );
      expect(
        routeRegistry.containsPath(FinanceRoutes.categories.path),
        isTrue,
      );
    });

    test('registers exactly four routes — no more, no fewer', () {
      const FinanceModule().register(registry);
      expect(registry.get<RouteRegistry>().length, 4);
    });

    test('route names resolve back to the correct RouteDefinition', () {
      const FinanceModule().register(registry);

      final routeRegistry = registry.get<RouteRegistry>();
      expect(
        routeRegistry.findByName('finance-accounts')?.path,
        '/finance/accounts',
      );
    });
  });

  group('FinanceModule — ViewModel resolution', () {
    late ServiceRegistry registry;

    setUp(() {
      registry = ServiceRegistry()
        ..registerSingleton<FeatureRegistry>(FeatureRegistry())
        ..registerSingleton<RouteRegistry>(RouteRegistry())
        ..registerSingleton<StartupPipeline>(StartupPipeline());
      // AccountsViewModel is real as of Sprint 8C Step 4 and resolves down
      // to the persistence stack via its injected use cases.
      _seedStorageStandIns(registry);
    });

    test('resolves FinanceHomeViewModel', () {
      const FinanceModule().register(registry);
      expect(registry.get<FinanceHomeViewModel>(), isA<FinanceHomeViewModel>());
    });

    test('resolves AccountsViewModel', () {
      const FinanceModule().register(registry);
      expect(registry.get<AccountsViewModel>(), isA<AccountsViewModel>());
    });

    test('resolves TransactionsViewModel', () {
      const FinanceModule().register(registry);
      expect(
        registry.get<TransactionsViewModel>(),
        isA<TransactionsViewModel>(),
      );
    });

    test('resolves CategoriesViewModel', () {
      const FinanceModule().register(registry);
      expect(registry.get<CategoriesViewModel>(), isA<CategoriesViewModel>());
    });

    test('every ViewModel exposes a placeholder loading state', () {
      const FinanceModule().register(registry);
      expect(registry.get<FinanceHomeViewModel>().state.isLoading, isTrue);
      expect(registry.get<AccountsViewModel>().state.isLoading, isTrue);
      expect(registry.get<TransactionsViewModel>().state.isLoading, isTrue);
      expect(registry.get<CategoriesViewModel>().state.isLoading, isTrue);
    });
  });

  group('Pages — construct successfully', () {
    test('FinanceHomePage constructs with a resolved FinanceHomeViewModel',
        () {
      final registry = ServiceRegistry()
        ..registerSingleton<FeatureRegistry>(FeatureRegistry())
        ..registerSingleton<RouteRegistry>(RouteRegistry())
        ..registerSingleton<StartupPipeline>(StartupPipeline());
      _seedStorageStandIns(registry);
      const FinanceModule().register(registry);

      expect(
        () => FinanceHomePage(viewModel: registry.get<FinanceHomeViewModel>()),
        returnsNormally,
      );
    });

    test('AccountsPage constructs with a resolved AccountsViewModel', () {
      final registry = ServiceRegistry()
        ..registerSingleton<FeatureRegistry>(FeatureRegistry())
        ..registerSingleton<RouteRegistry>(RouteRegistry())
        ..registerSingleton<StartupPipeline>(StartupPipeline());
      _seedStorageStandIns(registry);
      const FinanceModule().register(registry);

      expect(
        () => AccountsPage(viewModel: registry.get<AccountsViewModel>()),
        returnsNormally,
      );
    });

    test('TransactionsPage constructs with a resolved TransactionsViewModel',
        () {
      final registry = ServiceRegistry()
        ..registerSingleton<FeatureRegistry>(FeatureRegistry())
        ..registerSingleton<RouteRegistry>(RouteRegistry())
        ..registerSingleton<StartupPipeline>(StartupPipeline());
      _seedStorageStandIns(registry);
      const FinanceModule().register(registry);

      expect(
        () => TransactionsPage(viewModel: registry.get<TransactionsViewModel>()),
        returnsNormally,
      );
    });

    test('CategoriesPage constructs with a resolved CategoriesViewModel', () {
      final registry = ServiceRegistry()
        ..registerSingleton<FeatureRegistry>(FeatureRegistry())
        ..registerSingleton<RouteRegistry>(RouteRegistry())
        ..registerSingleton<StartupPipeline>(StartupPipeline());
      _seedStorageStandIns(registry);
      const FinanceModule().register(registry);

      expect(
        () => CategoriesPage(viewModel: registry.get<CategoriesViewModel>()),
        returnsNormally,
      );
    });

    test('each page exposes the ViewModel instance it was given', () {
      final registry = ServiceRegistry()
        ..registerSingleton<FeatureRegistry>(FeatureRegistry())
        ..registerSingleton<RouteRegistry>(RouteRegistry())
        ..registerSingleton<StartupPipeline>(StartupPipeline());
      _seedStorageStandIns(registry);
      const FinanceModule().register(registry);

      final viewModel = registry.get<CategoriesViewModel>();
      final page = CategoriesPage(viewModel: viewModel);
      expect(page.viewModel, same(viewModel));
    });
  });

  group('Runtime discovers Finance routes', () {
    test('RouteRegistry reflects Finance routes after FinanceModule.register',
        () {
      final registry = ServiceRegistry()
        ..registerSingleton<FeatureRegistry>(FeatureRegistry())
        ..registerSingleton<RouteRegistry>(RouteRegistry())
        ..registerSingleton<StartupPipeline>(StartupPipeline());

      const FinanceModule().register(registry);

      final router = ApplicationRouter(registry: registry.get<RouteRegistry>());
      expect(router.canResolveByPath('/finance'), isTrue);
      expect(router.canResolveByPath('/finance/accounts'), isTrue);
      expect(router.canResolveByPath('/finance/transactions'), isTrue);
      expect(router.canResolveByPath('/finance/categories'), isTrue);
      expect(router.canResolveByName('finance'), isTrue);
    });
  });
}
