import 'package:feature_tasks/src/data/migrations/create_tasks_table_migration.dart';
import 'package:feature_tasks/src/data/schema/tasks_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_migration_context.dart';

void main() {
  late FakeMigrationContext ctx;
  late CreateTasksTableMigration migration;

  setUp(() {
    ctx = FakeMigrationContext();
    migration = const CreateTasksTableMigration();
  });

  group('CreateTasksTableMigration', () {
    test('has version 1', () {
      expect(migration.version, 1);
    });

    group('up()', () {
      test('creates the tasks table', () async {
        await migration.up(ctx);

        final createTable =
            ctx.executedStatements.firstWhere((s) => s.contains('CREATE TABLE'));
        expect(createTable, contains(TasksSchema.tasksTable));
      });

      test('declares task_id as PRIMARY KEY', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.first;
        expect(createTable, contains(TasksSchema.taskId));
        expect(createTable, contains('PRIMARY KEY'));
      });

      test('declares all required NOT NULL columns', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          TasksSchema.taskWorkspaceId,
          TasksSchema.taskTitle,
          TasksSchema.taskStatus,
          TasksSchema.taskCreatedAt,
          TasksSchema.taskUpdatedAt,
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

      test('description, due_date, completed_at, and deleted_at are nullable',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          TasksSchema.taskDescription,
          TasksSchema.taskDueDate,
          TasksSchema.taskCompletedAt,
          TasksSchema.taskDeletedAt,
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
        for (final value in ['todo', 'inProgress', 'completed', 'archived']) {
          expect(createTable, contains(value));
        }
      });

      test('title has a CHECK constraint rejecting empty/whitespace values',
          () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final titleLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(TasksSchema.taskTitle));
        expect(titleLine, contains('CHECK'));
      });

      test('creates the workspace_id index', () async {
        await migration.up(ctx);

        expect(
          ctx.executedStatements.any(
            (s) =>
                s.contains('CREATE INDEX') &&
                s.contains('idx_tasks_workspace_id') &&
                s.contains(TasksSchema.taskWorkspaceId),
          ),
          isTrue,
        );
      });

      test('creates the workspace+status partial index excluding soft-deleted rows',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements
            .firstWhere((s) => s.contains('idx_tasks_workspace_status'));
        expect(indexStatement, contains(TasksSchema.taskStatus));
        expect(indexStatement, contains('WHERE'));
        expect(indexStatement, contains('${TasksSchema.taskDeletedAt} IS NULL'));
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
      test('drops the tasks table', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements
              .any((s) => s.contains('DROP TABLE') && s.contains(TasksSchema.tasksTable)),
          isTrue,
        );
      });

      test('drops both indexes', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any((s) => s.contains('idx_tasks_workspace_id')),
          isTrue,
        );
        expect(
          ctx.executedStatements.any((s) => s.contains('idx_tasks_workspace_status')),
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
