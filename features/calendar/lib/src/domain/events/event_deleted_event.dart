import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';

final class EventDeletedEvent extends DomainEvent {
  const EventDeletedEvent({
    required this.eventId,
    required this.workspaceId,
    required this.timestamp,
  });

  final EventId eventId;
  final String workspaceId;
  final DateTime timestamp;
}
