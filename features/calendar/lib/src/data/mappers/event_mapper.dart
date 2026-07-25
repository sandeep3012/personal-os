import 'package:feature_calendar/src/data/models/event_row.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';

/// Converts between the domain [Event] entity and the persistence
/// [EventRow] model. Pure conversion only — no validation, no repository
/// calls, no SQL, no business rules. Mirrors Notes' `NoteMapper`.
///
/// [Event] never represents a soft-deleted row: [EventDao]'s read methods
/// already exclude soft-deleted rows (`deleted_at IS NULL`), so a domain
/// [Event] instance can never have been loaded from a deleted row in the
/// first place. Consequently [toRow] always sets [EventRow.deletedAt] to
/// `null`.
final class EventMapper {
  const EventMapper();

  /// Converts a persisted [EventRow] to a domain [Event].
  ///
  /// Throws [CalendarException] if [EventRow.status] does not correspond
  /// to a value this mapper recognizes — corrupted or unsupported
  /// persisted data must fail loudly rather than be silently coerced.
  Event toEntity(EventRow row) {
    return Event(
      id: EventId(row.eventId),
      workspaceId: row.workspaceId,
      title: row.title,
      timeRange: EventTimeRange(start: row.startTime, end: row.endTime),
      location: row.location,
      description: row.description,
      status: _statusFromColumnValue(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Event] to a persistable [EventRow].
  EventRow toRow(Event event) {
    return EventRow(
      eventId: event.id.value,
      workspaceId: event.workspaceId,
      title: event.title,
      description: event.description,
      location: event.location,
      startTime: event.timeRange.start,
      endTime: event.timeRange.end,
      status: event.status.name,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      deletedAt: null,
    );
  }

  EventStatus _statusFromColumnValue(String value) {
    for (final status in EventStatus.values) {
      if (status.name == value) return status;
    }
    throw CalendarException(
      message: 'Unrecognized status value persisted: "$value"',
    );
  }
}
