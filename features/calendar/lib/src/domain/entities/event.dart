import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';

/// An Event aggregate root — a single scheduled occurrence a user has put
/// on their calendar (mirrors Notes/Goals' standalone-aggregate shape).
/// There is no owning Calendar/Schedule entity; grouping, if ever
/// introduced, happens through the platform Entity Linking Service, not
/// through a field on this entity.
///
/// Business invariants enforced here:
/// - [title] must not be empty and must not exceed 200 characters (mirrors
///   Note/Goal/Task/Habit's title invariant).
/// - [description] must not exceed 20,000 characters (mirrors
///   `Note.content`).
/// - [location] must not exceed 200 characters.
/// - [timeRange] enforces `end` after `start` on its own construction (see
///   [EventTimeRange]) — this constructor does not duplicate that check.
/// - Status transitions are only permitted per the approved transition
///   table — enforced by [transitionTo], not by direct field mutation
///   (this class has no public status setter).
final class Event {
  Event({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.timeRange,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.location = '',
    this.description = '',
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const CalendarException(message: 'Event title must not be empty');
    }
    if (title.length > 200) {
      throw const CalendarException(
        message: 'Event title must not exceed 200 characters',
      );
    }
    if (location.length > 200) {
      throw const CalendarException(
        message: 'Event location must not exceed 200 characters',
      );
    }
    if (description.length > 20000) {
      throw const CalendarException(
        message: 'Event description must not exceed 20000 characters',
      );
    }
  }

  final EventId id;
  final String workspaceId;
  final String title;

  /// The scheduled start/end of this event. Validated by [EventTimeRange]
  /// itself — always `end` strictly after `start`.
  final EventTimeRange timeRange;

  /// Where the event takes place. Defaults to an empty string — an Event
  /// may have no location.
  final String location;

  /// The free-form body of the event. Defaults to an empty string — an
  /// Event may be title-only.
  final String description;

  final EventStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this event with the supplied fields replaced.
  ///
  /// Does not change [status] — use [transitionTo] for status changes.
  /// Mirrors `Note.copyWith` rejecting status as an updatable field.
  Event copyWith({
    String? title,
    EventTimeRange? timeRange,
    String? location,
    String? description,
    DateTime? updatedAt,
  }) =>
      Event(
        id: id,
        workspaceId: workspaceId,
        title: title ?? this.title,
        timeRange: timeRange ?? this.timeRange,
        location: location ?? this.location,
        description: description ?? this.description,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy of this event transitioned to [next].
  ///
  /// Throws [CalendarException] if [next] is not reachable from [status]
  /// per the approved transition table:
  ///
  /// ```
  /// active   -> archived
  /// archived -> (none — terminal)
  /// ```
  Event transitionTo(EventStatus next, {required DateTime now}) {
    if (!status.canTransitionTo(next)) {
      throw CalendarException(
        message: 'Cannot transition Event from ${status.name} to ${next.name}',
      );
    }
    return Event(
      id: id,
      workspaceId: workspaceId,
      title: title,
      timeRange: timeRange,
      location: location,
      description: description,
      status: next,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Event && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Event(id: $id, title: $title, status: ${status.name})';
}
