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
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/di/finance_module.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/services/category_summary_service.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_deleted_specification.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_updated_specification.dart';
import 'package:feature_finance/src/domain/specifications/transaction_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/specifications/transfer_can_be_created_specification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

import '../data/dao/fake_finance_database_executor.dart';
import '../data/repositories/fake_finance_transaction_runner.dart';

/// Verifies that [FinanceModule] composes the *entire* Sprint 8A application
/// layer (domain services, specifications, use cases) on top of the Sprint
/// 8B persistence layer, against a real [ServiceRegistry].
///
/// This is composition-only: it proves every type *resolves* with correctly
/// injected dependencies. It does not exercise business behavior — that is
/// covered by each use case's own unit tests and the Sprint 8B integration
/// tests.
void main() {
  late ServiceRegistry registry;

  setUp(() {
    registry = ServiceRegistry()
      ..registerSingleton<FeatureRegistry>(FeatureRegistry())
      ..registerSingleton<RouteRegistry>(RouteRegistry())
      ..registerSingleton<StartupPipeline>(StartupPipeline());

    final executor = FakeFinanceDatabaseExecutor();
    registry
      ..registerSingleton<IFinanceDatabaseExecutor>(executor)
      ..registerSingleton<IFinanceTransactionRunner>(
        FakeFinanceTransactionRunner(executor),
      );

    const FinanceModule().register(registry);
  });

  group('FinanceModule — domain services', () {
    test('resolves IdGenerator', () {
      expect(registry.get<IdGenerator>(), isA<IdGenerator>());
    });

    test('resolves BalanceCalculationService', () {
      expect(
        registry.get<BalanceCalculationService>(),
        isA<BalanceCalculationService>(),
      );
    });

    test('resolves CategorySummaryService', () {
      expect(
        registry.get<CategorySummaryService>(),
        isA<CategorySummaryService>(),
      );
    });

    test('resolves TransferService with IdGenerator injected', () {
      expect(registry.get<TransferService>(), isA<TransferService>());
    });
  });

  group('FinanceModule — specifications', () {
    test('resolves AccountCanBeDeletedSpecification', () {
      expect(
        registry.get<AccountCanBeDeletedSpecification>(),
        isA<AccountCanBeDeletedSpecification>(),
      );
    });

    test('resolves AccountCanBeUpdatedSpecification', () {
      expect(
        registry.get<AccountCanBeUpdatedSpecification>(),
        isA<AccountCanBeUpdatedSpecification>(),
      );
    });

    test('resolves TransactionCanBeCreatedSpecification', () {
      expect(
        registry.get<TransactionCanBeCreatedSpecification>(),
        isA<TransactionCanBeCreatedSpecification>(),
      );
    });

    test('resolves TransferCanBeCreatedSpecification', () {
      expect(
        registry.get<TransferCanBeCreatedSpecification>(),
        isA<TransferCanBeCreatedSpecification>(),
      );
    });
  });

  group('FinanceModule — every Sprint 8A use case resolves', () {
    test('CreateAccountUseCase', () {
      expect(registry.get<CreateAccountUseCase>(), isA<CreateAccountUseCase>());
    });

    test('UpdateAccountUseCase', () {
      expect(registry.get<UpdateAccountUseCase>(), isA<UpdateAccountUseCase>());
    });

    test('DeleteAccountUseCase', () {
      expect(registry.get<DeleteAccountUseCase>(), isA<DeleteAccountUseCase>());
    });

    test('GetAccountsUseCase', () {
      expect(registry.get<GetAccountsUseCase>(), isA<GetAccountsUseCase>());
    });

    test('GetAccountByIdUseCase', () {
      expect(
        registry.get<GetAccountByIdUseCase>(),
        isA<GetAccountByIdUseCase>(),
      );
    });

    test('GetAccountBalanceUseCase', () {
      expect(
        registry.get<GetAccountBalanceUseCase>(),
        isA<GetAccountBalanceUseCase>(),
      );
    });

    test('AddExpenseUseCase', () {
      expect(registry.get<AddExpenseUseCase>(), isA<AddExpenseUseCase>());
    });

    test('AddIncomeUseCase', () {
      expect(registry.get<AddIncomeUseCase>(), isA<AddIncomeUseCase>());
    });

    test('CreateTransferUseCase', () {
      expect(
        registry.get<CreateTransferUseCase>(),
        isA<CreateTransferUseCase>(),
      );
    });

    test('UpdateTransactionUseCase', () {
      expect(
        registry.get<UpdateTransactionUseCase>(),
        isA<UpdateTransactionUseCase>(),
      );
    });

    test('DeleteTransactionUseCase', () {
      expect(
        registry.get<DeleteTransactionUseCase>(),
        isA<DeleteTransactionUseCase>(),
      );
    });

    test('GetTransactionsByAccountUseCase', () {
      expect(
        registry.get<GetTransactionsByAccountUseCase>(),
        isA<GetTransactionsByAccountUseCase>(),
      );
    });

    test('GetTransactionsByPeriodUseCase', () {
      expect(
        registry.get<GetTransactionsByPeriodUseCase>(),
        isA<GetTransactionsByPeriodUseCase>(),
      );
    });

    test('QueryTransactionsUseCase', () {
      expect(
        registry.get<QueryTransactionsUseCase>(),
        isA<QueryTransactionsUseCase>(),
      );
    });

    test('GetTotalExpensesUseCase', () {
      expect(
        registry.get<GetTotalExpensesUseCase>(),
        isA<GetTotalExpensesUseCase>(),
      );
    });

    test('GetTotalIncomeUseCase', () {
      expect(
        registry.get<GetTotalIncomeUseCase>(),
        isA<GetTotalIncomeUseCase>(),
      );
    });

    test('GetNetPositionUseCase', () {
      expect(
        registry.get<GetNetPositionUseCase>(),
        isA<GetNetPositionUseCase>(),
      );
    });

    test('GetCategorySummaryUseCase', () {
      expect(
        registry.get<GetCategorySummaryUseCase>(),
        isA<GetCategorySummaryUseCase>(),
      );
    });
  });

  group('FinanceModule — repository injection correctness', () {
    test('use cases depending on IAccountRepository receive the same '
        'singleton instance the repository binding resolves to', () {
      final repo = registry.get<IAccountRepository>();
      final useCase = registry.get<GetAccountsUseCase>();
      // GetAccountsUseCase holds a private reference; we can only prove
      // correct wiring indirectly — by confirming the repository singleton
      // itself is stable across resolutions (lazy singleton semantics),
      // which is what every use case factory captures at construction time.
      expect(identical(repo, registry.get<IAccountRepository>()), isTrue);
      expect(useCase, isA<GetAccountsUseCase>());
    });

    test('use case factories produce a fresh instance on every resolution',
        () {
      final first = registry.get<CreateAccountUseCase>();
      final second = registry.get<CreateAccountUseCase>();
      expect(identical(first, second), isFalse);
    });

    test('repositories remain lazy singletons even as use cases are '
        'resolved repeatedly', () {
      registry.get<CreateAccountUseCase>();
      registry.get<GetAccountsUseCase>();
      final repoFirst = registry.get<IAccountRepository>();
      final repoSecond = registry.get<IAccountRepository>();
      expect(identical(repoFirst, repoSecond), isTrue);
    });
  });

  group('FinanceModule — dependency graph integrity', () {
    test('resolving every registered application type completes without '
        'circular dependency (no stack overflow / infinite recursion)', () {
      expect(() {
        registry.get<IdGenerator>();
        registry.get<BalanceCalculationService>();
        registry.get<CategorySummaryService>();
        registry.get<TransferService>();
        registry.get<AccountCanBeDeletedSpecification>();
        registry.get<AccountCanBeUpdatedSpecification>();
        registry.get<TransactionCanBeCreatedSpecification>();
        registry.get<TransferCanBeCreatedSpecification>();
        registry.get<CreateAccountUseCase>();
        registry.get<UpdateAccountUseCase>();
        registry.get<DeleteAccountUseCase>();
        registry.get<GetAccountsUseCase>();
        registry.get<GetAccountByIdUseCase>();
        registry.get<GetAccountBalanceUseCase>();
        registry.get<AddExpenseUseCase>();
        registry.get<AddIncomeUseCase>();
        registry.get<CreateTransferUseCase>();
        registry.get<UpdateTransactionUseCase>();
        registry.get<DeleteTransactionUseCase>();
        registry.get<GetTransactionsByAccountUseCase>();
        registry.get<GetTransactionsByPeriodUseCase>();
        registry.get<QueryTransactionsUseCase>();
        registry.get<GetTotalExpensesUseCase>();
        registry.get<GetTotalIncomeUseCase>();
        registry.get<GetNetPositionUseCase>();
        registry.get<GetCategorySummaryUseCase>();
      }, returnsNormally);
    });
  });

  group('FinanceModule — duplicate registration prevention', () {
    test('registering FinanceModule a second time on the same registry '
        'throws', () {
      expect(
        () => const FinanceModule().register(registry),
        throwsA(anything),
      );
    });
  });
}
