import 'package:feature_calendar/src/data/migrations/create_events_table_migration.dart';
import 'package:feature_calendar/src/data/schema/events_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_migration_context.dart';

void main() {
  late FakeMigrationContext ctx;
  late CreateEventsTableMigration migration;

  setUp(() {
    ctx = FakeMigrationContext();
    migration = const CreateEventsTableMigration();
  });

  group('CreateEventsTableMigration', () {
    test('has version 1', () {
      expect(migration.version, 1);
    });

    group('up()', () {
      test('creates the events table', () async {
        await migration.up(ctx);

        final createTable =
            ctx.executedStatements.firstWhere((s) => s.contains('CREATE TABLE'));
        expect(createTable, contains(EventsSchema.eventsTable));
      });

      test('declares event_id as PRIMARY KEY', () async {
        await migration.up(ctx);

        final createTable = ctx.executedStatements.first;
        expect(createTable, contains(EventsSchema.eventId));
        expect(createTable, contains('PRIMARY KEY'));
      });

      test('declares all required NOT NULL columns', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          EventsSchema.eventWorkspaceId,
          EventsSchema.eventTitle,
          EventsSchema.eventStartTime,
          EventsSchema.eventEndTime,
          EventsSchema.eventStatus,
          EventsSchema.eventCreatedAt,
          EventsSchema.eventUpdatedAt,
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

      test('description, location, and deleted_at are nullable', () async {
        await migration.up(ctx);
        final createTable = ctx.executedStatements.first;

        for (final column in [
          EventsSchema.eventDescription,
          EventsSchema.eventLocation,
          EventsSchema.eventDeletedAt,
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
            .firstWhere((l) => l.trim().startsWith(EventsSchema.eventStatus));
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
            .firstWhere((line) => line.trim().startsWith(EventsSchema.eventTitle));
        expect(titleLine, contains('CHECK'));
      });

      test('creates the workspace_id index', () async {
        await migration.up(ctx);

        expect(
          ctx.executedStatements.any(
            (s) =>
                s.contains('CREATE INDEX') &&
                s.contains('idx_events_workspace_id') &&
                s.contains(EventsSchema.eventWorkspaceId),
          ),
          isTrue,
        );
      });

      test('creates the workspace+status partial index excluding soft-deleted rows',
          () async {
        await migration.up(ctx);

        final indexStatement = ctx.executedStatements
            .firstWhere((s) => s.contains('idx_events_workspace_status'));
        expect(indexStatement, contains(EventsSchema.eventStatus));
        expect(indexStatement, contains('WHERE'));
        expect(indexStatement, contains('${EventsSchema.eventDeletedAt} IS NULL'));
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
      test('drops the events table', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements
              .any((s) => s.contains('DROP TABLE') && s.contains(EventsSchema.eventsTable)),
          isTrue,
        );
      });

      test('drops both indexes', () async {
        await migration.down(ctx);

        expect(
          ctx.executedStatements.any((s) => s.contains('idx_events_workspace_id')),
          isTrue,
        );
        expect(
          ctx.executedStatements.any((s) => s.contains('idx_events_workspace_status')),
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
