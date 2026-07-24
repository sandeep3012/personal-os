import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';

final class EventCreatedEvent extends DomainEvent {
  const EventCreatedEvent({
    required this.eventId,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.timestamp,
  });

  final EventId eventId;
  final String workspaceId;
  final String title;
  final EventStatus status;
  final DateTime timestamp;
}
