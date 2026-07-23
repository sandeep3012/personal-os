import 'package:feature_goals/src/data/migrations/create_goals_table_migration.dart';
import 'package:feature_goals/src/data/schema/goals_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_migration_context.dart';

void main() {
  late FakeMigrationContext ctx;
  late CreateGoalsTableMigration migration;

  setUp(() {
    ctx = FakeMigrationContext();
    migration = const CreateGoalsTableMigration();
  });

  group('CreateGoalsTableMigration', () {
    test('has version 1', () {
      expect(migration.version, 1);
    });

    group('up()', () {
      test('creates the goals table', () async {
        await migration.up(ctx);

        final createTable =
            ctx.executedStatements.firstWhere((s) => s.contains('CREATE TABLE'));
        expect(createTable, contains(GoalsSchema.goalsTable));
      });

      test('declares goal_id as PRIMARY KEY', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.first;
        expect(createTable, contains(GoalsSchema.goalId));
        expect(createTable, contains('PRIMARY KEY'));
      });

      test('declares all required NOT NULL columns', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          GoalsSchema.goalWorkspaceId,
          GoalsSchema.goalName,
          GoalsSchema.goalTargetValue,
          GoalsSchema.goalStatus,
          GoalsSchema.goalCreatedAt,
          GoalsSchema.goalUpdatedAt,
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

      test('description, target_date, and deleted_at are nullable', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          GoalsSchema.goalDescription,
          GoalsSchema.goalTargetDate,
          GoalsSchema.goalDeletedAt,
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
        for (final value in ['active', 'completed', 'archived']) {
          expect(createTable, contains(value));
        }
      });

      test('target_value has a CHECK constraint requiring a positive value',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final targetLine = createTable
            .split('\n')
            .firstWhere((l) => l.trim().startsWith(GoalsSchema.goalTargetValue));
        expect(targetLine, contains('CHECK'));
      });

      test('name has a CHECK constraint rejecting empty/whitespace values', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final nameLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(GoalsSchema.goalName));
        expect(nameLine, contains('CHECK'));
      });

      test('creates the workspace_id index', () async {
        await migration.up(ctx);

        expect(
          ctx.executedStatements.any(
            (s) =>
                s.contains('CREATE INDEX') &&
                s.contains('idx_goals_workspace_id') &&
                s.contains(GoalsSchema.goalWorkspaceId),
          ),
          isTrue,
        );
      });

      test('creates the workspace+status partial index excluding soft-deleted rows',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements
            .firstWhere((s) => s.contains('idx_goals_workspace_status'));
        expect(indexStatement, contains(GoalsSchema.goalStatus));
        expect(indexStatement, contains('WHERE'));
        expect(indexStatement, contains('${GoalsSchema.goalDeletedAt} IS NULL'));
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
      test('drops the goals table', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements
              .any((s) => s.contains('DROP TABLE') && s.contains(GoalsSchema.goalsTable)),
          isTrue,
        );
      });

      test('drops both indexes', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any((s) => s.contains('idx_goals_workspace_id')),
          isTrue,
        );
        expect(
          ctx.executedStatements.any((s) => s.contains('idx_goals_workspace_status')),
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
