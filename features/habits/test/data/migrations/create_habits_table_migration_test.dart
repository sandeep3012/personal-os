import 'package:feature_habits/src/data/migrations/create_habits_table_migration.dart';
import 'package:feature_habits/src/data/schema/habits_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_migration_context.dart';

void main() {
  late FakeMigrationContext ctx;
  late CreateHabitsTableMigration migration;

  setUp(() {
    ctx = FakeMigrationContext();
    migration = const CreateHabitsTableMigration();
  });

  group('CreateHabitsTableMigration', () {
    test('has version 1', () {
      expect(migration.version, 1);
    });

    group('up()', () {
      test('creates the habits table', () async {
        await migration.up(ctx);

        final createTable =
            ctx.executedStatements.firstWhere((s) => s.contains('CREATE TABLE'));
        expect(createTable, contains(HabitsSchema.habitsTable));
      });

      test('declares habit_id as PRIMARY KEY', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.first;
        expect(createTable, contains(HabitsSchema.habitId));
        expect(createTable, contains('PRIMARY KEY'));
      });

      test('declares all required NOT NULL columns', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          HabitsSchema.habitWorkspaceId,
          HabitsSchema.habitName,
          HabitsSchema.habitFrequency,
          HabitsSchema.habitStatus,
          HabitsSchema.habitCreatedAt,
          HabitsSchema.habitUpdatedAt,
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

      test('description, last_completed_at, and deleted_at are nullable', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          HabitsSchema.habitDescription,
          HabitsSchema.habitLastCompletedAt,
          HabitsSchema.habitDeletedAt,
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

        expect(createTable, contains('CHECK'));
        for (final value in ['active', 'archived']) {
          expect(createTable, contains(value));
        }
      });

      test('frequency has a CHECK constraint matching the domain enum', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final value in ['daily', 'weekly']) {
          expect(createTable, contains(value));
        }
      });

      test('name has a CHECK constraint rejecting empty/whitespace values', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final nameLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(HabitsSchema.habitName));
        expect(nameLine, contains('CHECK'));
      });

      test('creates the workspace_id index', () async {
        await migration.up(ctx);

        expect(
          ctx.executedStatements.any(
            (s) =>
                s.contains('CREATE INDEX') &&
                s.contains('idx_habits_workspace_id') &&
                s.contains(HabitsSchema.habitWorkspaceId),
          ),
          isTrue,
        );
      });

      test('creates the workspace+status partial index excluding soft-deleted rows',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements
            .firstWhere((s) => s.contains('idx_habits_workspace_status'));
        expect(indexStatement, contains(HabitsSchema.habitStatus));
        expect(indexStatement, contains('WHERE'));
        expect(indexStatement, contains('${HabitsSchema.habitDeletedAt} IS NULL'));
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
      test('drops the habits table', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements
              .any((s) => s.contains('DROP TABLE') && s.contains(HabitsSchema.habitsTable)),
          isTrue,
        );
      });

      test('drops both indexes', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any((s) => s.contains('idx_habits_workspace_id')),
          isTrue,
        );
        expect(
          ctx.executedStatements.any((s) => s.contains('idx_habits_workspace_status')),
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
