/// Table and column name constants for the Calendar SQLite schema.
///
/// Single source of truth for identifiers referenced by both the schema
/// migration and the repository/DAO layer — mirrors Notes' `NotesSchema`.
abstract final class EventsSchema {
  static const eventsTable = 'events';

  static const eventId = 'event_id';
  static const eventWorkspaceId = 'workspace_id';
  static const eventTitle = 'title';
  static const eventDescription = 'description';
  static const eventLocation = 'location';
  static const eventStartTime = 'start_time';
  static const eventEndTime = 'end_time';
  static const eventStatus = 'status';
  static const eventCreatedAt = 'created_at';
  static const eventUpdatedAt = 'updated_at';
  static const eventDeletedAt = 'deleted_at';

  // ── Column ordering (DAO insert/update column lists) ─────────────────────

  static const List<String> eventColumns = [
    eventId,
    eventWorkspaceId,
    eventTitle,
    eventDescription,
    eventLocation,
    eventStartTime,
    eventEndTime,
    eventStatus,
    eventCreatedAt,
    eventUpdatedAt,
    eventDeletedAt,
  ];
}
