import 'package:feature_calendar/src/data/schema/events_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `events` table and its supporting indexes.
///
/// [Event.status] is a `TEXT` column constrained to the values of the
/// actual `EventStatus` enum (`active`, `archived` — see
/// `event_status.dart`). Mirrors Notes' `CreateNotesTableMigration`
/// exactly, including its current status: declared for parity and as
/// schema-as-code documentation, not yet wired into a runtime migration
/// runner, since the active executor is the hand-rolled in-memory/
/// file-backed engine rather than a real SQL engine (same as
/// Notes/Goals/Habits/Finance/Tasks today).
///
/// Soft delete is represented by nullable [EventsSchema.eventDeletedAt]
/// rather than a boolean flag, so the deletion moment is recoverable for
/// audit/debugging — the [Event] entity itself has no such field; this is
/// purely a storage-layer concern.
final class CreateEventsTableMigration extends Migration {
  const CreateEventsTableMigration() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${EventsSchema.eventsTable} (
        ${EventsSchema.eventId}          TEXT    PRIMARY KEY,
        ${EventsSchema.eventWorkspaceId} TEXT    NOT NULL,
        ${EventsSchema.eventTitle}       TEXT    NOT NULL CHECK (length(trim(${EventsSchema.eventTitle})) > 0),
        ${EventsSchema.eventDescription} TEXT,
        ${EventsSchema.eventLocation}    TEXT,
        ${EventsSchema.eventStartTime}   TEXT    NOT NULL,
        ${EventsSchema.eventEndTime}     TEXT    NOT NULL,
        ${EventsSchema.eventStatus}      TEXT    NOT NULL CHECK (${EventsSchema.eventStatus} IN ('active', 'archived')),
        ${EventsSchema.eventCreatedAt}   TEXT    NOT NULL,
        ${EventsSchema.eventUpdatedAt}   TEXT    NOT NULL,
        ${EventsSchema.eventDeletedAt}   TEXT
      )
    ''');

    // Serves IEventRepository.findAll(workspaceId) and general workspace
    // scoping.
    await ctx.execute('''
      CREATE INDEX idx_events_workspace_id
      ON ${EventsSchema.eventsTable} (${EventsSchema.eventWorkspaceId})
    ''');

    // Serves IEventRepository.findByStatus(workspaceId, status); excludes
    // soft-deleted rows.
    await ctx.execute('''
      CREATE INDEX idx_events_workspace_status
      ON ${EventsSchema.eventsTable} (${EventsSchema.eventWorkspaceId}, ${EventsSchema.eventStatus})
      WHERE ${EventsSchema.eventDeletedAt} IS NULL
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_events_workspace_status');
    await ctx.execute('DROP INDEX IF EXISTS idx_events_workspace_id');
    await ctx.execute('DROP TABLE IF EXISTS ${EventsSchema.eventsTable}');
  }
}
