import 'package:feature_calendar/src/data/schema/events_schema.dart';

/// A single, unmapped row from the `events` table.
///
/// [EventRow] is a persistence-layer data shape only — it has no business
/// methods, no validation, and no relationship to the domain `Event`
/// entity. Mapping between [EventRow] and `Event` is a repository-layer
/// concern, not a DAO concern. Mirrors Notes' `NoteRow`.
final class EventRow {
  const EventRow({
    required this.eventId,
    required this.workspaceId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.location = '',
    this.deletedAt,
  });

  final String eventId;
  final String workspaceId;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Builds an [EventRow] from a raw SQL result row.
  factory EventRow.fromMap(Map<String, Object?> map) {
    final deletedAtValue = map[EventsSchema.eventDeletedAt] as String?;
    return EventRow(
      eventId: map[EventsSchema.eventId]! as String,
      workspaceId: map[EventsSchema.eventWorkspaceId]! as String,
      title: map[EventsSchema.eventTitle]! as String,
      description: map[EventsSchema.eventDescription] as String? ?? '',
      location: map[EventsSchema.eventLocation] as String? ?? '',
      startTime: DateTime.parse(map[EventsSchema.eventStartTime]! as String),
      endTime: DateTime.parse(map[EventsSchema.eventEndTime]! as String),
      status: map[EventsSchema.eventStatus]! as String,
      createdAt: DateTime.parse(map[EventsSchema.eventCreatedAt]! as String),
      updatedAt: DateTime.parse(map[EventsSchema.eventUpdatedAt]! as String),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [EventsSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        EventsSchema.eventId: eventId,
        EventsSchema.eventWorkspaceId: workspaceId,
        EventsSchema.eventTitle: title,
        EventsSchema.eventDescription: description,
        EventsSchema.eventLocation: location,
        EventsSchema.eventStartTime: startTime.toIso8601String(),
        EventsSchema.eventEndTime: endTime.toIso8601String(),
        EventsSchema.eventStatus: status,
        EventsSchema.eventCreatedAt: createdAt.toIso8601String(),
        EventsSchema.eventUpdatedAt: updatedAt.toIso8601String(),
        EventsSchema.eventDeletedAt: deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.eventId == eventId &&
          other.workspaceId == workspaceId &&
          other.title == title &&
          other.description == description &&
          other.location == location &&
          other.startTime == startTime &&
          other.endTime == endTime &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        eventId,
        workspaceId,
        title,
        description,
        location,
        startTime,
        endTime,
        status,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'EventRow(eventId: $eventId, title: $title)';
}
