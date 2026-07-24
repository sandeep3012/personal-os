import 'package:feature_calendar/src/data/mappers/event_mapper.dart';
import 'package:feature_calendar/src/data/models/event_row.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = EventMapper();

  Event event({
    String id = 'event-1',
    String title = 'Standup',
    String location = 'Room A',
    String description = 'Daily sync',
    EventStatus status = EventStatus.active,
  }) {
    final now = DateTime(2024, 1, 1, 10, 30);
    return Event(
      id: EventId(id),
      workspaceId: 'ws-1',
      title: title,
      timeRange: EventTimeRange(
        start: DateTime(2024, 1, 2, 9),
        end: DateTime(2024, 1, 2, 10),
      ),
      location: location,
      description: description,
      status: status,
      createdAt: now,
      updatedAt: DateTime(2024, 2, 1, 8),
    );
  }

  group('EventMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(event(id: 'event-1', title: 'Standup'));

      expect(row.eventId, 'event-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.title, 'Standup');
      expect(row.description, 'Daily sync');
      expect(row.location, 'Room A');
      expect(row.startTime, DateTime(2024, 1, 2, 9));
      expect(row.endTime, DateTime(2024, 1, 2, 10));
    });

    test('maps every EventStatus to its enum name', () {
      for (final status in EventStatus.values) {
        final row = mapper.toRow(event(status: status));
        expect(row.status, status.name);
      }
    });

    test('always maps deletedAt to null (domain Event is never soft-deleted)',
        () {
      final row = mapper.toRow(event());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode content', () {
      final row = mapper.toRow(event(title: 'Café meetup ☕ 買い物'));
      expect(row.title, 'Café meetup ☕ 買い物');
    });
  });

  group('EventMapper.toEntity', () {
    EventRow row({
      String id = 'event-1',
      String title = 'Standup',
      String status = 'active',
    }) {
      final now = DateTime(2024, 1, 1, 10, 30);
      return EventRow(
        eventId: id,
        workspaceId: 'ws-1',
        title: title,
        description: 'Daily sync',
        location: 'Room A',
        startTime: DateTime(2024, 1, 2, 9),
        endTime: DateTime(2024, 1, 2, 10),
        status: status,
        createdAt: now,
        updatedAt: DateTime(2024, 2, 1, 8),
      );
    }

    test('maps all scalar fields', () {
      final entity = mapper.toEntity(row(id: 'event-2', title: 'Review'));

      expect(entity.id, const EventId('event-2'));
      expect(entity.workspaceId, 'ws-1');
      expect(entity.title, 'Review');
      expect(entity.timeRange.start, DateTime(2024, 1, 2, 9));
      expect(entity.timeRange.end, DateTime(2024, 1, 2, 10));
    });

    test('converts every status column value back to its enum', () {
      for (final status in EventStatus.values) {
        final entity = mapper.toEntity(row(status: status.name));
        expect(entity.status, status);
      }
    });

    test('throws CalendarException for an unrecognized status value', () {
      expect(
        () => mapper.toEntity(row(status: 'not_a_real_status')),
        throwsA(isA<CalendarException>()),
      );
    });
  });

  group('EventMapper round-trip', () {
    test('Event -> EventRow -> Event preserves all domain fields', () {
      final original = event(
        id: 'event-rt',
        title: 'Round Trip',
        status: EventStatus.active,
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.location, original.location);
      expect(restored.timeRange, original.timeRange);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trips an archived event', () {
      final original = event(status: EventStatus.archived);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.status, EventStatus.archived);
    });
  });
}
