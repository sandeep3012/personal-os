import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';

/// Archiving is a distinct, terminal, business-meaningful transition,
/// not an ordinary field update — mirrors `NoteArchivedEvent`.
final class EventArchivedEvent extends DomainEvent {
  const EventArchivedEvent({
    required this.eventId,
    required this.workspaceId,
    required this.timestamp,
  });

  final EventId eventId;
  final String workspaceId;
  final DateTime timestamp;
}
