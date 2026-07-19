import 'package:feature_finance/src/data/migrations/create_transactions_table_migration.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_migration_context.dart';

void main() {
  late FakeMigrationContext ctx;
  late CreateTransactionsTableMigration migration;

  setUp(() {
    ctx = FakeMigrationContext();
    migration = const CreateTransactionsTableMigration();
  });

  group('CreateTransactionsTableMigration', () {
    test('has version 2 (runs after accounts table migration)', () {
      expect(migration.version, 2);
    });

    group('up()', () {
      test('creates the transactions table', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.firstWhere(
          (s) => s.contains('CREATE TABLE'),
        );
        expect(createTable, contains(FinanceSchema.transactionsTable));
      });

      test('declares transaction_id as PRIMARY KEY', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        expect(createTable, contains(FinanceSchema.transactionId));
        expect(createTable, contains('PRIMARY KEY'));
      });

      test('declares all required NOT NULL columns', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          FinanceSchema.transactionWorkspaceId,
          FinanceSchema.transactionAccountId,
          FinanceSchema.transactionType,
          FinanceSchema.transactionAmountMinor,
          FinanceSchema.transactionCurrency,
          FinanceSchema.transactionDate,
          FinanceSchema.transactionCreatedAt,
          FinanceSchema.transactionUpdatedAt,
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

      test('nullable columns have no NOT NULL constraint', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          FinanceSchema.transactionTransferPairId,
          FinanceSchema.transactionCategoryId,
          FinanceSchema.transactionPayee,
          FinanceSchema.transactionNote,
          FinanceSchema.transactionAttachmentIds,
          FinanceSchema.transactionDeletedAt,
        ]) {
          final columnLine = createTable
              .split('\n')
              .firstWhere((line) => line.trim().startsWith(column));
          expect(
            columnLine,
            isNot(contains('NOT NULL')),
            reason: '$column should be nullable',
          );
        }
      });

      test('amount_minor is INTEGER with a positive-value CHECK constraint',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final amountLine = createTable.split('\n').firstWhere(
              (line) => line.trim().startsWith(FinanceSchema.transactionAmountMinor),
            );
        expect(amountLine, contains('INTEGER'));
        expect(amountLine, contains('CHECK'));
        expect(amountLine, contains('> 0'));
      });

      test('transaction_type has a CHECK constraint matching the domain enum',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final typeLine = createTable.split('\n').firstWhere(
              (line) => line.trim().startsWith(FinanceSchema.transactionType),
            );
        expect(typeLine, contains('CHECK'));
        for (final value in ['expense', 'income', 'transfer']) {
          expect(typeLine, contains(value));
        }
      });

      test('currency has a CHECK constraint enforcing 3-letter format',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final currencyLine = createTable.split('\n').firstWhere(
              (line) => line.trim().startsWith(FinanceSchema.transactionCurrency),
            );
        expect(currencyLine, contains('CHECK'));
        expect(currencyLine, contains('length'));
      });

      test('account_id has a foreign key to accounts with ON DELETE RESTRICT',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final accountIdLine = createTable.split('\n').firstWhere(
              (line) => line.trim().startsWith(FinanceSchema.transactionAccountId),
            );
        expect(accountIdLine, contains('REFERENCES'));
        expect(accountIdLine, contains(FinanceSchema.accountsTable));
        expect(accountIdLine, contains('ON DELETE RESTRICT'));
      });

      test(
          'transfer_pair_id has no foreign key constraint (Step 1.6 refinement)',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final transferPairLine = createTable.split('\n').firstWhere(
              (line) =>
                  line.trim().startsWith(FinanceSchema.transactionTransferPairId),
            );
        expect(transferPairLine, isNot(contains('REFERENCES')));
        expect(transferPairLine, isNot(contains('ON DELETE')));
      });

      test('transfer_pair_id has a CHECK constraint preventing self-reference',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final transferPairLine = createTable.split('\n').firstWhere(
              (line) =>
                  line.trim().startsWith(FinanceSchema.transactionTransferPairId),
            );
        expect(transferPairLine, contains('CHECK'));
        expect(
          transferPairLine,
          contains(
            '${FinanceSchema.transactionTransferPairId} != ${FinanceSchema.transactionId}',
          ),
        );
      });

      test('does not cascade hard deletes anywhere in the table definition',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        expect(createTable, isNot(contains('ON DELETE CASCADE')));
      });

      test('creates an index for account_id + transaction_date lookups',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements.firstWhere(
          (s) => s.contains('idx_transactions_account_date'),
        );
        expect(indexStatement, contains(FinanceSchema.transactionAccountId));
        expect(indexStatement, contains(FinanceSchema.transactionDate));
        expect(indexStatement, contains('${FinanceSchema.transactionDeletedAt} IS NULL'));
      });

      test('creates an index for workspace_id + transaction_date lookups',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements.firstWhere(
          (s) => s.contains('idx_transactions_workspace_date'),
        );
        expect(indexStatement, contains(FinanceSchema.transactionWorkspaceId));
        expect(indexStatement, contains(FinanceSchema.transactionDate));
      });

      test('creates an index for category_id + transaction_date lookups',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements.firstWhere(
          (s) => s.contains('idx_transactions_category_date'),
        );
        expect(indexStatement, contains(FinanceSchema.transactionCategoryId));
        expect(
          indexStatement,
          contains('${FinanceSchema.transactionCategoryId} IS NOT NULL'),
        );
      });

      test('creates an index for transfer_pair_id lookups', () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements.firstWhere(
          (s) => s.contains('idx_transactions_transfer_pair_id'),
        );
        expect(indexStatement, contains(FinanceSchema.transactionTransferPairId));
      });

      test('creates a general workspace_id index', () async {
        await migration.up(ctx);

        expect(
          ctx.executedStatements.any(
            (s) =>
                s.contains('CREATE INDEX') &&
                s.contains('idx_transactions_workspace_id'),
          ),
          isTrue,
        );
      });

      test('executes table creation before index creation', () async {
        await migration.up(ctx);

        final tableIndex =
            ctx.executedStatements.indexWhere((s) => s.contains('CREATE TABLE'));
        final firstIndexIndex =
            ctx.executedStatements.indexWhere((s) => s.contains('CREATE INDEX'));

        expect(tableIndex, lessThan(firstIndexIndex));
      });
    });

    group('down()', () {
      test('drops the transactions table', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any(
            (s) => s.contains('DROP TABLE') && s.contains(FinanceSchema.transactionsTable),
          ),
          isTrue,
        );
      });

      test('drops all five indexes', () async {
        await migration.down(ctx);

        for (final indexName in [
          'idx_transactions_account_date',
          'idx_transactions_workspace_date',
          'idx_transactions_category_date',
          'idx_transactions_transfer_pair_id',
          'idx_transactions_workspace_id',
        ]) {
          expect(
            ctx.executedStatements.any((s) => s.contains(indexName)),
            isTrue,
            reason: '$indexName should be dropped',
          );
        }
      });

      test('drops indexes before dropping the table', () async {
        await migration.down(ctx);

        final tableDropIndex =
            ctx.executedStatements.indexWhere((s) => s.contains('DROP TABLE'));
        final lastIndexDropIndex =
            ctx.executedStatements.lastIndexWhere((s) => s.contains('DROP INDEX'));

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
