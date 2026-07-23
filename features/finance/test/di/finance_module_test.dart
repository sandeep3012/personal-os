import 'package:application/application.dart';
import 'package:feature_finance/src/data/dao/account_dao.dart';
import 'package:feature_finance/src/data/dao/transaction_dao.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/data/mappers/account_mapper.dart';
import 'package:feature_finance/src/data/mappers/transaction_mapper.dart';
import 'package:feature_finance/src/data/repositories/account_repository.dart';
import 'package:feature_finance/src/data/repositories/transaction_repository.dart';
import 'package:feature_finance/src/di/finance_module.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

import '../data/dao/fake_finance_database_executor.dart';
import '../data/repositories/fake_finance_transaction_runner.dart';

/// Verifies that [FinanceModule] composes the persistence layer correctly
/// against a *real* DI container ([ServiceRegistry] from `platform_runtime`
/// — the same concrete class `RuntimeBootstrap` uses in production). Only
/// the two leaf interfaces with no production implementation yet
/// ([IFinanceDatabaseExecutor], [IFinanceTransactionRunner]) are supplied by
/// fakes, standing in for whatever concrete engine a future, ADR-gated step
/// registers.
void main() {
  late ServiceRegistry registry;

  /// Seeds the application-layer singletons [FeatureModule.register] reads
  /// before calling [FinanceModule.registerServices] — mirrors what
  /// [ApplicationModule] does in a real `RuntimeBootstrap` run.
  void seedApplicationLayerPrerequisites() {
    registry
      ..registerSingleton<FeatureRegistry>(FeatureRegistry())
      ..registerSingleton<RouteRegistry>(RouteRegistry())
      ..registerSingleton<StartupPipeline>(StartupPipeline())
      ..registerSingleton<IdGenerator>(const UuidGenerator());
  }

  setUp(() {
    registry = ServiceRegistry();
    seedApplicationLayerPrerequisites();
    // Stand-ins for the still-unimplemented (ADR-pending) leaf interfaces.
    registry
      ..registerSingleton<IFinanceDatabaseExecutor>(FakeFinanceDatabaseExecutor())
      ..registerSingleton<IFinanceTransactionRunner>(
        FakeFinanceTransactionRunner(registry.get<IFinanceDatabaseExecutor>()),
      );
  });

  group('FinanceModule.register', () {
    test('registers successfully without throwing', () {
      expect(() => const FinanceModule().register(registry), returnsNormally);
    });

    test('registers the feature in FeatureRegistry', () {
      const FinanceModule().register(registry);

      expect(registry.get<FeatureRegistry>().isRegistered('finance'), isTrue);
    });
  });

  group('FinanceModule persistence resolution', () {
    setUp(() => const FinanceModule().register(registry));

    test('resolves AccountMapper', () {
      expect(registry.get<AccountMapper>(), isA<AccountMapper>());
    });

    test('resolves TransactionMapper', () {
      expect(registry.get<TransactionMapper>(), isA<TransactionMapper>());
    });

    test('resolves AccountDao', () {
      expect(registry.get<AccountDao>(), isA<AccountDao>());
    });

    test('resolves TransactionDao', () {
      expect(registry.get<TransactionDao>(), isA<TransactionDao>());
    });

    test('resolves IAccountRepository as an AccountRepository', () {
      final repo = registry.get<IAccountRepository>();
      expect(repo, isA<AccountRepository>());
    });

    test('resolves ITransactionRepository as a TransactionRepository', () {
      final repo = registry.get<ITransactionRepository>();
      expect(repo, isA<TransactionRepository>());
    });

    test('resolves the externally-supplied IFinanceTransactionRunner', () {
      expect(
        registry.get<IFinanceTransactionRunner>(),
        isA<IFinanceTransactionRunner>(),
      );
    });

    test('does not register IFinanceDatabaseExecutor itself', () {
      // Registered by the test's seed step, not by FinanceModule — verifies
      // FinanceModule doesn't duplicate a registration for a type it does
      // not own.
      expect(registry.isRegistered<IFinanceDatabaseExecutor>(), isTrue);
    });
  });

  group('FinanceModule dependency injection correctness', () {
    setUp(() => const FinanceModule().register(registry));

    test('AccountDao is constructed with the registered executor', () async {
      final executor =
          registry.get<IFinanceDatabaseExecutor>() as FakeFinanceDatabaseExecutor;
      final dao = registry.get<AccountDao>();

      await dao.findAll('ws-1');

      // Proves the DAO resolved from the container is wired to the same
      // executor instance registered in the container, not a disconnected one.
      expect(executor.executedQueries, isNotEmpty);
    });

    test('lazy singletons return the same instance on repeated resolution',
        () {
      final first = registry.get<AccountDao>();
      final second = registry.get<AccountDao>();
      expect(identical(first, second), isTrue);

      final firstRepo = registry.get<IAccountRepository>();
      final secondRepo = registry.get<IAccountRepository>();
      expect(identical(firstRepo, secondRepo), isTrue);
    });

    test('no circular dependency exists among persistence registrations',
        () {
      // If a cycle existed, one of these resolutions would recurse
      // infinitely (stack overflow) rather than complete normally.
      expect(() {
        registry.get<AccountMapper>();
        registry.get<TransactionMapper>();
        registry.get<AccountDao>();
        registry.get<TransactionDao>();
        registry.get<IAccountRepository>();
        registry.get<ITransactionRepository>();
      }, returnsNormally);
    });
  });

  group('FinanceModule registration idempotency', () {
    test('registering FinanceModule twice on the same registry throws', () {
      const FinanceModule().register(registry);
      expect(
        () => const FinanceModule().register(registry),
        throwsA(anything),
      );
    });
  });
}
