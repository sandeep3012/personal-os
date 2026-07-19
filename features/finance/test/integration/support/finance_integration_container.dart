import 'package:application/application.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/data/database/in_memory_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/in_memory_finance_transaction_runner.dart';
import 'package:feature_finance/src/di/finance_module.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Composes the real Finance persistence stack exactly as production does:
/// a real [ServiceRegistry], [FinanceModule.register] wiring DAOs, mappers,
/// and repositories — with only the two leaf interfaces that have no
/// production implementation yet substituted by genuine in-memory
/// infrastructure (per this step's testing philosophy: "avoid mocking
/// DAOs, mappers, or repositories; only substitute infrastructure where no
/// production implementation exists").
final class FinanceIntegrationContainer {
  factory FinanceIntegrationContainer() {
    final registry = ServiceRegistry()
      ..registerSingleton<FeatureRegistry>(FeatureRegistry())
      ..registerSingleton<RouteRegistry>(RouteRegistry())
      ..registerSingleton<StartupPipeline>(StartupPipeline());

    final executor = InMemoryFinanceDatabaseExecutor();
    final runner = InMemoryFinanceTransactionRunner(executor);

    registry
      ..registerSingleton<IFinanceDatabaseExecutor>(executor)
      ..registerSingleton<IFinanceTransactionRunner>(runner);

    const FinanceModule().register(registry);

    return FinanceIntegrationContainer._(
      registry: registry,
      executor: executor,
      runner: runner,
      accountRepository: registry.get<IAccountRepository>(),
      transactionRepository: registry.get<ITransactionRepository>(),
    );
  }

  FinanceIntegrationContainer._({
    required this.registry,
    required this.executor,
    required this.runner,
    required this.accountRepository,
    required this.transactionRepository,
  });

  final ServiceRegistry registry;
  final InMemoryFinanceDatabaseExecutor executor;
  final InMemoryFinanceTransactionRunner runner;
  final IAccountRepository accountRepository;
  final ITransactionRepository transactionRepository;
}
