import 'package:feature_notes/src/data/migrations/create_notes_table_migration.dart';
import 'package:feature_notes/src/data/schema/notes_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_migration_context.dart';

void main() {
  late FakeMigrationContext ctx;
  late CreateNotesTableMigration migration;

  setUp(() {
    ctx = FakeMigrationContext();
    migration = const CreateNotesTableMigration();
  });

  group('CreateNotesTableMigration', () {
    test('has version 1', () {
      expect(migration.version, 1);
    });

    group('up()', () {
      test('creates the notes table', () async {
        await migration.up(ctx);

        final createTable =
            ctx.executedStatements.firstWhere((s) => s.contains('CREATE TABLE'));
        expect(createTable, contains(NotesSchema.notesTable));
      });

      test('declares note_id as PRIMARY KEY', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.first;
        expect(createTable, contains(NotesSchema.noteId));
        expect(createTable, contains('PRIMARY KEY'));
      });

      test('declares all required NOT NULL columns', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          NotesSchema.noteWorkspaceId,
          NotesSchema.noteTitle,
          NotesSchema.noteTags,
          NotesSchema.noteStatus,
          NotesSchema.noteCreatedAt,
          NotesSchema.noteUpdatedAt,
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

      test('content and deleted_at are nullable', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          NotesSchema.noteContent,
          NotesSchema.noteDeletedAt,
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
            .firstWhere((l) => l.trim().startsWith(NotesSchema.noteStatus));
        expect(statusLine, contains('CHECK'));
        for (final value in ['active', 'archived']) {
          expect(createTable, contains(value));
        }
      });

      test('title has a CHECK constraint rejecting empty/whitespace values', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final titleLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(NotesSchema.noteTitle));
        expect(titleLine, contains('CHECK'));
      });

      test('tags has a default value of an empty JSON array', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        final tagsLine = createTable
            .split('\n')
            .firstWhere((line) => line.trim().startsWith(NotesSchema.noteTags));
        expect(tagsLine, contains('DEFAULT'));
      });

      test('creates the workspace_id index', () async {
        await migration.up(ctx);

        expect(
          ctx.executedStatements.any(
            (s) =>
                s.contains('CREATE INDEX') &&
                s.contains('idx_notes_workspace_id') &&
                s.contains(NotesSchema.noteWorkspaceId),
          ),
          isTrue,
        );
      });

      test('creates the workspace+status partial index excluding soft-deleted rows',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements
            .firstWhere((s) => s.contains('idx_notes_workspace_status'));
        expect(indexStatement, contains(NotesSchema.noteStatus));
        expect(indexStatement, contains('WHERE'));
        expect(indexStatement, contains('${NotesSchema.noteDeletedAt} IS NULL'));
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
      test('drops the notes table', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements
              .any((s) => s.contains('DROP TABLE') && s.contains(NotesSchema.notesTable)),
          isTrue,
        );
      });

      test('drops both indexes', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any((s) => s.contains('idx_notes_workspace_id')),
          isTrue,
        );
        expect(
          ctx.executedStatements.any((s) => s.contains('idx_notes_workspace_status')),
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
