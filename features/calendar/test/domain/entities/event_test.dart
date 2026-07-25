import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

EventTimeRange _range({DateTime? start, DateTime? end}) => EventTimeRange(
      start: start ?? DateTime(2026, 1, 1, 9),
      end: end ?? DateTime(2026, 1, 1, 10),
    );

Event _event({
  String title = 'Title',
  String location = '',
  String description = '',
  EventTimeRange? timeRange,
  EventStatus status = EventStatus.active,
}) {
  final now = DateTime(2026, 1, 1);
  return Event(
    id: const EventId('event-1'),
    workspaceId: _ws,
    title: title,
    timeRange: timeRange ?? _range(),
    location: location,
    description: description,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Event construction', () {
    test('rejects an empty title', () {
      expect(() => _event(title: '   '), throwsA(isA<CalendarException>()));
    });

    test('rejects a title longer than 200 characters', () {
      expect(() => _event(title: 'a' * 201), throwsA(isA<CalendarException>()));
    });

    test('rejects a location longer than 200 characters', () {
      expect(
        () => _event(location: 'a' * 201),
        throwsA(isA<CalendarException>()),
      );
    });

    test('rejects a description longer than 20000 characters', () {
      expect(
        () => _event(description: 'a' * 20001),
        throwsA(isA<CalendarException>()),
      );
    });

    test('defaults location and description to empty string', () {
      final event = _event();
      expect(event.location, '');
      expect(event.description, '');
    });
  });

  group('Event.copyWith', () {
    test('replaces only the supplied fields', () {
      final event = _event(title: 'Original', location: 'Office');
      final updated = event.copyWith(title: 'Renamed');

      expect(updated.title, 'Renamed');
      expect(updated.location, 'Office');
      expect(updated.status, event.status);
    });

    test('never changes status', () {
      final event = _event();
      final updated = event.copyWith(title: 'X');
      expect(updated.status, EventStatus.active);
    });
  });

  group('Event.transitionTo', () {
    test('allows active -> archived', () {
      final event = _event();
      final archived =
          event.transitionTo(EventStatus.archived, now: DateTime(2026, 2, 1));

      expect(archived.status, EventStatus.archived);
      expect(archived.updatedAt, DateTime(2026, 2, 1));
    });

    test('rejects archived -> archived', () {
      final event = _event(status: EventStatus.archived);
      expect(
        () => event.transitionTo(EventStatus.archived, now: DateTime(2026, 2, 1)),
        throwsA(isA<CalendarException>()),
      );
    });
  });

  group('Event equality', () {
    test('two events with the same id are equal regardless of other fields', () {
      final a = _event(title: 'A');
      final b = _event(title: 'B');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
