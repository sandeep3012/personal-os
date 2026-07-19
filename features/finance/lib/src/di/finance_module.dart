import 'package:application/application.dart';
import 'package:feature_finance/src/application/use_cases/account/create_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/delete_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_balance_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_by_id_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/update_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_category_summary_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_net_position_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_expenses_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_income_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_expense_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_income_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/create_transfer_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/delete_transaction_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/get_transactions_by_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/get_transactions_by_period_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/query_transactions_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/update_transaction_use_case.dart';
import 'package:feature_finance/src/data/dao/account_dao.dart';
import 'package:feature_finance/src/data/dao/transaction_dao.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/data/mappers/account_mapper.dart';
import 'package:feature_finance/src/data/mappers/transaction_mapper.dart';
import 'package:feature_finance/src/data/repositories/account_repository.dart';
import 'package:feature_finance/src/data/repositories/transaction_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/services/category_summary_service.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_deleted_specification.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_updated_specification.dart';
import 'package:feature_finance/src/domain/specifications/transaction_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/specifications/transfer_can_be_created_specification.dart';
import 'package:feature_finance/src/presentation/routes/finance_routes.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/categories_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_home_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/transactions_view_model.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/utils/id_generator.dart';

/// Wires the complete Finance application layer into the Personal OS DI
/// container: persistence (Sprint 8B), domain services, specifications, and
/// every Sprint 8A use case.
///
/// Registers routes for [FinanceHomePage], [AccountsPage],
/// [TransactionsPage], and [CategoriesPage]. No startup steps yet; none are
/// required until a feature actually needs one (e.g. category seeding).
///
/// ## Dependency graph
///
/// ```
/// AccountRepository      → AccountDao        → IFinanceDatabaseExecutor (external)
/// AccountRepository      → AccountMapper
/// TransactionRepository  → TransactionDao    → IFinanceDatabaseExecutor (external)
/// TransactionRepository  → TransactionMapper
/// TransactionRepository  → IFinanceTransactionRunner (external)
///
/// TransferService                     → IdGenerator
/// AccountCanBeDeletedSpecification    → IAccountRepository, ITransactionRepository
/// AccountCanBeUpdatedSpecification    → IAccountRepository
/// TransactionCanBeCreatedSpecification→ IAccountRepository
/// TransferCanBeCreatedSpecification   → IAccountRepository
///
/// Every use case                      → IAccountRepository and/or ITransactionRepository,
///                                        plus its own specification/service where required
/// ```
///
/// [IFinanceDatabaseExecutor] and [IFinanceTransactionRunner] are **not**
/// registered by this module — no concrete implementation of either exists
/// yet (both deferred pending the storage-engine ADR, same as
/// `platform_storage`'s `IDatabase`). This module expects a concrete binding
/// for each to already exist in the container by the time a repository (or
/// anything depending on one) is first resolved.
///
/// `CurrencyMinorUnits` and `MoneyMinorUnitsConverter` remain unregistered:
/// both are `abstract final class`es with only `static` members.
///
/// [WorkspaceContext] is also **not** registered by this module — it is
/// application-level infrastructure registered by `ApplicationModule`
/// (ADR-004), which must precede any [FeatureModule] per the existing
/// module-ordering constraint (ADR-003). `AccountsViewModel` resolves it
/// from the locator like any other external dependency; Finance never
/// invents or hardcodes a workspace identifier.
final class FinanceModule extends FeatureModule {
  const FinanceModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'finance',
        name: 'Finance',
        version: '0.1.0',
        description:
            'Personal financial tracking: accounts, income, expenses, and '
            'transfers. Routes and startup steps are added in a later '
            'Sprint 8C step.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry
      ..register(FinanceRoutes.root)
      ..register(FinanceRoutes.accounts)
      ..register(FinanceRoutes.transactions)
      ..register(FinanceRoutes.categories);
  }

  @override
  void registerServices(IDependencyRegistrar registrar) {
    // The registrar passed by RuntimeBootstrap is always a ServiceRegistry,
    // which implements both IDependencyRegistrar and IServiceLocator — the
    // same safe cast FeatureModule.register itself relies on. Reading via
    // the locator inside each lazy factory means registration order across
    // modules does not matter.
    final locator = registrar as IServiceLocator;

    _registerPersistence(registrar, locator);
    _registerDomainServices(registrar, locator);
    _registerSpecifications(registrar, locator);
    _registerUseCases(registrar, locator);
    _registerViewModels(registrar, locator);
  }

  // ── Presentation ────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution, matching the use-case
  // convention above — ViewModels are recreated per page visit, not shared.

  void _registerViewModels(
    IDependencyRegistrar registrar,
    IServiceLocator locator,
  ) {
    registrar.registerFactory<FinanceHomeViewModel>(
      () => FinanceHomeViewModel(
        getAccountsUseCase: locator.get<GetAccountsUseCase>(),
        getAccountBalanceUseCase: locator.get<GetAccountBalanceUseCase>(),
        getTotalIncomeUseCase: locator.get<GetTotalIncomeUseCase>(),
        getTotalExpensesUseCase: locator.get<GetTotalExpensesUseCase>(),
        getNetPositionUseCase: locator.get<GetNetPositionUseCase>(),
        queryTransactionsUseCase: locator.get<QueryTransactionsUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<AccountsViewModel>(
      () => AccountsViewModel(
        getAccountsUseCase: locator.get<GetAccountsUseCase>(),
        createAccountUseCase: locator.get<CreateAccountUseCase>(),
        updateAccountUseCase: locator.get<UpdateAccountUseCase>(),
        deleteAccountUseCase: locator.get<DeleteAccountUseCase>(),
        getAccountBalanceUseCase: locator.get<GetAccountBalanceUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<TransactionsViewModel>(
      () => TransactionsViewModel(
        getAccountsUseCase: locator.get<GetAccountsUseCase>(),
        queryTransactionsUseCase: locator.get<QueryTransactionsUseCase>(),
        addExpenseUseCase: locator.get<AddExpenseUseCase>(),
        addIncomeUseCase: locator.get<AddIncomeUseCase>(),
        updateTransactionUseCase: locator.get<UpdateTransactionUseCase>(),
        deleteTransactionUseCase: locator.get<DeleteTransactionUseCase>(),
        createTransferUseCase: locator.get<CreateTransferUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<CategoriesViewModel>(
      () => CategoriesViewModel(
        getCategorySummaryUseCase: locator.get<GetCategorySummaryUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
  }

  // ── Persistence (Sprint 8B) ────────────────────────────────────────────────

  void _registerPersistence(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerLazySingleton<AccountMapper>(() => const AccountMapper());
    registrar.registerLazySingleton<TransactionMapper>(
      () => const TransactionMapper(),
    );

    registrar.registerLazySingleton<AccountDao>(
      () => AccountDao(locator.get<IFinanceDatabaseExecutor>()),
    );
    registrar.registerLazySingleton<TransactionDao>(
      () => TransactionDao(locator.get<IFinanceDatabaseExecutor>()),
    );

    registrar.registerLazySingleton<IAccountRepository>(
      () => AccountRepository(
        accountDao: locator.get<AccountDao>(),
        accountMapper: locator.get<AccountMapper>(),
      ),
    );
    registrar.registerLazySingleton<ITransactionRepository>(
      () => TransactionRepository(
        transactionDao: locator.get<TransactionDao>(),
        transactionMapper: locator.get<TransactionMapper>(),
        transactionRunner: locator.get<IFinanceTransactionRunner>(),
      ),
    );
  }

  // ── Domain services ────────────────────────────────────────────────────────

  void _registerDomainServices(
    IDependencyRegistrar registrar,
    IServiceLocator locator,
  ) {
    registrar.registerLazySingleton<IdGenerator>(() => const UuidGenerator());
    registrar.registerLazySingleton<BalanceCalculationService>(
      () => const BalanceCalculationService(),
    );
    registrar.registerLazySingleton<CategorySummaryService>(
      () => const CategorySummaryService(),
    );
    registrar.registerLazySingleton<TransferService>(
      () => TransferService(idGenerator: locator.get<IdGenerator>()),
    );
  }

  // ── Specifications ─────────────────────────────────────────────────────────

  void _registerSpecifications(
    IDependencyRegistrar registrar,
    IServiceLocator locator,
  ) {
    registrar.registerLazySingleton<AccountCanBeDeletedSpecification>(
      () => AccountCanBeDeletedSpecification(
        accountRepository: locator.get<IAccountRepository>(),
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );
    registrar.registerLazySingleton<AccountCanBeUpdatedSpecification>(
      () => AccountCanBeUpdatedSpecification(
        accountRepository: locator.get<IAccountRepository>(),
      ),
    );
    registrar.registerLazySingleton<TransactionCanBeCreatedSpecification>(
      () => TransactionCanBeCreatedSpecification(
        accountRepository: locator.get<IAccountRepository>(),
      ),
    );
    registrar.registerLazySingleton<TransferCanBeCreatedSpecification>(
      () => TransferCanBeCreatedSpecification(
        accountRepository: locator.get<IAccountRepository>(),
      ),
    );
  }

  // ── Use cases ──────────────────────────────────────────────────────────────
  //
  // Registered via registerFactory (a fresh instance per resolution) —
  // matching the established FeatureModule convention (see SampleModule),
  // since use cases are cheap, stateless orchestrators, not shared state.

  void _registerUseCases(IDependencyRegistrar registrar, IServiceLocator locator) {
    // Accounts
    registrar.registerFactory<CreateAccountUseCase>(
      () => CreateAccountUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        idGenerator: locator.get<IdGenerator>(),
      ),
    );
    registrar.registerFactory<UpdateAccountUseCase>(
      () => UpdateAccountUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        specification: locator.get<AccountCanBeUpdatedSpecification>(),
      ),
    );
    registrar.registerFactory<DeleteAccountUseCase>(
      () => DeleteAccountUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        specification: locator.get<AccountCanBeDeletedSpecification>(),
      ),
    );
    registrar.registerFactory<GetAccountsUseCase>(
      () => GetAccountsUseCase(accountRepository: locator.get<IAccountRepository>()),
    );
    registrar.registerFactory<GetAccountByIdUseCase>(
      () => GetAccountByIdUseCase(
        accountRepository: locator.get<IAccountRepository>(),
      ),
    );
    registrar.registerFactory<GetAccountBalanceUseCase>(
      () => GetAccountBalanceUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        transactionRepository: locator.get<ITransactionRepository>(),
        balanceCalculationService: locator.get<BalanceCalculationService>(),
      ),
    );

    // Transactions
    registrar.registerFactory<AddExpenseUseCase>(
      () => AddExpenseUseCase(
        transactionRepository: locator.get<ITransactionRepository>(),
        idGenerator: locator.get<IdGenerator>(),
        specification: locator.get<TransactionCanBeCreatedSpecification>(),
      ),
    );
    registrar.registerFactory<AddIncomeUseCase>(
      () => AddIncomeUseCase(
        transactionRepository: locator.get<ITransactionRepository>(),
        idGenerator: locator.get<IdGenerator>(),
        specification: locator.get<TransactionCanBeCreatedSpecification>(),
      ),
    );
    registrar.registerFactory<CreateTransferUseCase>(
      () => CreateTransferUseCase(
        transactionRepository: locator.get<ITransactionRepository>(),
        transferService: locator.get<TransferService>(),
        specification: locator.get<TransferCanBeCreatedSpecification>(),
      ),
    );
    registrar.registerFactory<UpdateTransactionUseCase>(
      () => UpdateTransactionUseCase(
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );
    registrar.registerFactory<DeleteTransactionUseCase>(
      () => DeleteTransactionUseCase(
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );
    registrar.registerFactory<GetTransactionsByAccountUseCase>(
      () => GetTransactionsByAccountUseCase(
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );
    registrar.registerFactory<GetTransactionsByPeriodUseCase>(
      () => GetTransactionsByPeriodUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );
    registrar.registerFactory<QueryTransactionsUseCase>(
      () => QueryTransactionsUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );

    // Summary
    registrar.registerFactory<GetTotalExpensesUseCase>(
      () => GetTotalExpensesUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );
    registrar.registerFactory<GetTotalIncomeUseCase>(
      () => GetTotalIncomeUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );
    registrar.registerFactory<GetNetPositionUseCase>(
      () => GetNetPositionUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        transactionRepository: locator.get<ITransactionRepository>(),
      ),
    );
    registrar.registerFactory<GetCategorySummaryUseCase>(
      () => GetCategorySummaryUseCase(
        accountRepository: locator.get<IAccountRepository>(),
        transactionRepository: locator.get<ITransactionRepository>(),
        categorySummaryService: locator.get<CategorySummaryService>(),
      ),
    );
  }
}
