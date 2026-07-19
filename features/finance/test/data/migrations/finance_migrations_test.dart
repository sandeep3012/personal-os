import 'package:feature_finance/src/data/migrations/create_accounts_table_migration.dart';
import 'package:feature_finance/src/data/migrations/create_transactions_table_migration.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_storage/migrations/migration_runner.dart';

import 'fake_migration_context.dart';

/// Integration-level test proving both Finance migrations apply together,
/// in the correct order, via the shared [MigrationRunner] from
/// `platform_storage` — the same runner the app will use in production.
void main() {
  group('Finance schema migrations via MigrationRunner', () {
    test('accounts table is created before transactions table', () async {
      final runner = MigrationRunner()
        ..register(const CreateAccountsTableMigration())
        ..register(const CreateTransactionsTableMigration());
      final ctx = FakeMigrationContext();

      final result =
          await runner.migrate(context: ctx, fromVersion: 0, toVersion: 2);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.appliedVersions, [1, 2]);

      final accountsTableIndex = ctx.executedStatements.indexWhere(
        (s) => s.contains('CREATE TABLE') && s.contains(FinanceSchema.accountsTable),
      );
      final transactionsTableIndex = ctx.executedStatements.indexWhere(
        (s) =>
            s.contains('CREATE TABLE') && s.contains(FinanceSchema.transactionsTable),
      );

      expect(accountsTableIndex, greaterThanOrEqualTo(0));
      expect(transactionsTableIndex, greaterThan(accountsTableIndex));
    });

    test('registering both migrations does not throw duplicate-version error',
        () {
      expect(
        () => MigrationRunner()
          ..register(const CreateAccountsTableMigration())
          ..register(const CreateTransactionsTableMigration()),
        returnsNormally,
      );
    });

    test('rollback drops transactions table before accounts table', () async {
      final runner = MigrationRunner()
        ..register(const CreateAccountsTableMigration())
        ..register(const CreateTransactionsTableMigration());
      final ctx = FakeMigrationContext();

      final result =
          await runner.rollback(context: ctx, fromVersion: 2, toVersion: 0);

      expect(result.isSuccess, isTrue);

      final transactionsDropIndex = ctx.executedStatements.indexWhere(
        (s) => s.contains('DROP TABLE') && s.contains(FinanceSchema.transactionsTable),
      );
      final accountsDropIndex = ctx.executedStatements.indexWhere(
        (s) => s.contains('DROP TABLE') && s.contains(FinanceSchema.accountsTable),
      );

      expect(transactionsDropIndex, greaterThanOrEqualTo(0));
      expect(accountsDropIndex, greaterThan(transactionsDropIndex));
    });
  });
}
