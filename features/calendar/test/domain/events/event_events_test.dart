import 'package:feature_calendar/src/domain/events/event_archived_event.dart';
import 'package:feature_calendar/src/domain/events/event_created_event.dart';
import 'package:feature_calendar/src/domain/events/event_deleted_event.dart';
import 'package:feature_calendar/src/domain/events/event_updated_event.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

void main() {
  final now = DateTime(2026, 1, 1);

  test('EventCreatedEvent carries its fields', () {
    final event = EventCreatedEvent(
      eventId: const EventId('event-1'),
      workspaceId: _ws,
      title: 'Title',
      status: EventStatus.active,
      timestamp: now,
    );
    expect(event.eventId, const EventId('event-1'));
    expect(event.title, 'Title');
    expect(event.status, EventStatus.active);
  });

  test('EventUpdatedEvent carries its fields', () {
    final event = EventUpdatedEvent(
      eventId: const EventId('event-1'),
      workspaceId: _ws,
      title: 'Title',
      status: EventStatus.active,
      timestamp: now,
    );
    expect(event.title, 'Title');
  });

  test('EventArchivedEvent carries its fields', () {
    final event = EventArchivedEvent(
      eventId: const EventId('event-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.eventId, const EventId('event-1'));
    expect(event.workspaceId, _ws);
  });

  test('EventDeletedEvent carries its fields', () {
    final event = EventDeletedEvent(
      eventId: const EventId('event-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.timestamp, now);
  });
}
