import 'package:feature_assets/src/data/migrations/create_assets_table_migration.dart';
import 'package:feature_assets/src/data/schema/assets_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_migration_context.dart';

void main() {
  late FakeMigrationContext ctx;
  late CreateAssetsTableMigration migration;

  setUp(() {
    ctx = FakeMigrationContext();
    migration = const CreateAssetsTableMigration();
  });

  group('CreateAssetsTableMigration', () {
    test('has version 1', () {
      expect(migration.version, 1);
    });

    group('up()', () {
      test('creates the assets table', () async {
        await migration.up(ctx);

        final createTable =
            ctx.executedStatements.firstWhere((s) => s.contains('CREATE TABLE'));
        expect(createTable, contains(AssetsSchema.assetsTable));
      });

      test('declares asset_id as PRIMARY KEY', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.first;
        expect(createTable, contains(AssetsSchema.assetId));
        expect(createTable, contains('PRIMARY KEY'));
      });

      test('declares all required NOT NULL columns', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          AssetsSchema.assetWorkspaceId,
          AssetsSchema.assetName,
          AssetsSchema.assetCategory,
          AssetsSchema.assetValue,
          AssetsSchema.assetAcquisitionDate,
          AssetsSchema.assetStatus,
          AssetsSchema.assetCreatedAt,
          AssetsSchema.assetUpdatedAt,
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

      test('notes and deleted_at are nullable', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          AssetsSchema.assetNotes,
          AssetsSchema.assetDeletedAt,
        ]) {
          final line = createTable
              .split('\n')
              .firstWhere((l) => l.trim().startsWith(column));
          expect(line, isNot(contains('NOT NULL')), reason: '$column should be nullable');
        }
      });

      test('status has a CHECK constraint matching the domain enum', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final statusLine = createTable
            .split('\n')
            .firstWhere((l) => l.trim().startsWith(AssetsSchema.assetStatus));
        expect(statusLine, contains('CHECK'));
        for (final value in ['active', 'disposed', 'archived']) {
          expect(createTable, contains(value));
        }
      });

      test('name has a CHECK constraint rejecting empty/whitespace values', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final nameLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(AssetsSchema.assetName));
        expect(nameLine, contains('CHECK'));
      });

      test('creates the workspace_id index', () async {
        await migration.up(ctx);

        expect(
          ctx.executedStatements.any(
            (s) =>
                s.contains('CREATE INDEX') &&
                s.contains('idx_assets_workspace_id') &&
                s.contains(AssetsSchema.assetWorkspaceId),
          ),
          isTrue,
        );
      });

      test('creates the workspace+status partial index excluding soft-deleted rows',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements
            .firstWhere((s) => s.contains('idx_assets_workspace_status'));
        expect(indexStatement, contains(AssetsSchema.assetStatus));
        expect(indexStatement, contains('WHERE'));
        expect(indexStatement, contains('${AssetsSchema.assetDeletedAt} IS NULL'));
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
      test('drops the assets table', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements
              .any((s) => s.contains('DROP TABLE') && s.contains(AssetsSchema.assetsTable)),
          isTrue,
        );
      });

      test('drops both indexes', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any((s) => s.contains('idx_assets_workspace_id')),
          isTrue,
        );
        expect(
          ctx.executedStatements.any((s) => s.contains('idx_assets_workspace_status')),
          isTrue,
        );
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
