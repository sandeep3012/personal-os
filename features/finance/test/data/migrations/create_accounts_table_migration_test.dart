import 'package:feature_finance/src/data/migrations/create_accounts_table_migration.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_migration_context.dart';

void main() {
  late FakeMigrationContext ctx;
  late CreateAccountsTableMigration migration;

  setUp(() {
    ctx = FakeMigrationContext();
    migration = const CreateAccountsTableMigration();
  });

  group('CreateAccountsTableMigration', () {
    test('has version 1', () {
      expect(migration.version, 1);
    });

    group('up()', () {
      test('creates the accounts table', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.firstWhere(
          (s) => s.contains('CREATE TABLE'),
        );
        expect(createTable, contains(FinanceSchema.accountsTable));
      });

      test('declares account_id as PRIMARY KEY', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.first;
        expect(createTable, contains(FinanceSchema.accountId));
        expect(createTable, contains('PRIMARY KEY'));
      });

      test('declares all required NOT NULL columns', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          FinanceSchema.accountWorkspaceId,
          FinanceSchema.accountName,
          FinanceSchema.accountType,
          FinanceSchema.accountCurrency,
          FinanceSchema.accountOpeningBalanceMinor,
          FinanceSchema.accountIsActive,
          FinanceSchema.accountCreatedAt,
          FinanceSchema.accountUpdatedAt,
        ]) {
          final columnLine = createTable
              .split('\n')
              .firstWhere((line) => line.trim().startsWith(column));
          expect(
            columnLine,
            contains('NOT NULL'),
            reason: '$column should be NOT NULL',
          );
        }
      });

      test('deleted_at is nullable (no NOT NULL constraint)', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final deletedAtLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(FinanceSchema.accountDeletedAt));
        expect(deletedAtLine, isNot(contains('NOT NULL')));
      });

      test('opening_balance_minor is INTEGER (minor units, no Decimal)',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final balanceLine = createTable.split('\n').firstWhere(
              (line) =>
                  line.trim().startsWith(FinanceSchema.accountOpeningBalanceMinor),
            );
        expect(balanceLine, contains('INTEGER'));
      });

      test('account_type has a CHECK constraint matching the domain enum',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        expect(createTable, contains('CHECK'));
        for (final value in [
          'checking',
          'savings',
          'creditCard',
          'cash',
          'investment',
        ]) {
          expect(createTable, contains(value));
        }
      });

      test('currency has a CHECK constraint enforcing 3-letter format',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final currencyLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(FinanceSchema.accountCurrency));
        expect(currencyLine, contains('CHECK'));
        expect(currencyLine, contains('length'));
      });

      test('name has a CHECK constraint rejecting empty/whitespace values',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final nameLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(FinanceSchema.accountName));
        expect(nameLine, contains('CHECK'));
      });

      test('is_active has a CHECK constraint limiting values to 0 or 1',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final activeLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(FinanceSchema.accountIsActive));
        expect(activeLine, contains('CHECK'));
        expect(activeLine, contains('IN (0, 1)'));
      });

      test('creates the workspace_id index', () async {
        await migration.up(ctx);

        expect(
          ctx.executedStatements.any(
            (s) =>
                s.contains('CREATE INDEX') &&
                s.contains('idx_accounts_workspace_id') &&
                s.contains(FinanceSchema.accountWorkspaceId),
          ),
          isTrue,
        );
      });

      test('creates the workspace+active partial index excluding soft-deleted rows',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements.firstWhere(
          (s) => s.contains('idx_accounts_workspace_active'),
        );
        expect(indexStatement, contains(FinanceSchema.accountIsActive));
        expect(indexStatement, contains('WHERE'));
        expect(indexStatement, contains('${FinanceSchema.accountDeletedAt} IS NULL'));
      });

      test('executes table creation before index creation', () async {
        await migration.up(ctx);

        final tableIndex = ctx.executedStatements
            .indexWhere((s) => s.contains('CREATE TABLE'));
        final firstIndexIndex = ctx.executedStatements
            .indexWhere((s) => s.contains('CREATE INDEX'));

        expect(tableIndex, lessThan(firstIndexIndex));
      });
    });

    group('down()', () {
      test('drops the accounts table', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any(
            (s) => s.contains('DROP TABLE') && s.contains(FinanceSchema.accountsTable),
          ),
          isTrue,
        );
      });

      test('drops both indexes', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any((s) => s.contains('idx_accounts_workspace_id')),
          isTrue,
        );
        expect(
          ctx.executedStatements.any((s) => s.contains('idx_accounts_workspace_active')),
          isTrue,
        );
      });

      test('drops indexes before dropping the table', () async {
        await migration.down(ctx);

        final tableDropIndex = ctx.executedStatements
            .indexWhere((s) => s.contains('DROP TABLE'));
        final lastIndexDropIndex = ctx.executedStatements
            .lastIndexWhere((s) => s.contains('DROP INDEX'));

        expect(lastIndexDropIndex, lessThan(tableDropIndex));
      });

      test('uses IF EXISTS for idempotent rollback', () async {
        await migration.down(ctx);

        for (final statement in ctx.executedStatements) {
          expect(statement, contains('IF EXISTS'));
        }
      });
    });
  });
}
