import 'package:feature_calendar/src/application/use_cases/update_event_use_case.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

Event _existing({EventStatus status = EventStatus.active}) {
  final now = DateTime(2026, 1, 1);
  return Event(
    id: const EventId('event-1'),
    workspaceId: _ws,
    title: 'Original title',
    timeRange: EventTimeRange(start: DateTime(2026, 1, 1, 9), end: DateTime(2026, 1, 1, 10)),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeEventRepository repo;
  late UpdateEventUseCase useCase;

  setUp(() {
    repo = FakeEventRepository()..seed([_existing()]);
    useCase = UpdateEventUseCase(eventRepository: repo);
  });

  group('UpdateEventUseCase', () {
    test('updates the title', () async {
      final result = await useCase.execute(
        const UpdateEventInput(
          eventId: EventId('event-1'),
          workspaceId: _ws,
          title: 'Renamed',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'Renamed');
    });

    test('updates location and description', () async {
      final result = await useCase.execute(
        const UpdateEventInput(
          eventId: EventId('event-1'),
          workspaceId: _ws,
          location: 'New Room',
          description: 'Updated agenda',
        ),
      );

      expect(result.valueOrNull!.location, 'New Room');
      expect(result.valueOrNull!.description, 'Updated agenda');
    });

    test('updates the time range', () async {
      final newRange =
          EventTimeRange(start: DateTime(2026, 2, 1, 9), end: DateTime(2026, 2, 1, 11));

      final result = await useCase.execute(
        UpdateEventInput(
          eventId: const EventId('event-1'),
          workspaceId: _ws,
          timeRange: newRange,
        ),
      );

      expect(result.valueOrNull!.timeRange, newRange);
    });

    test('does not change status', () async {
      final result = await useCase.execute(
        const UpdateEventInput(
          eventId: EventId('event-1'),
          workspaceId: _ws,
          title: 'Renamed',
        ),
      );

      expect(result.valueOrNull!.status, EventStatus.active);
    });

    test('fails when the event does not exist', () async {
      final result = await useCase.execute(
        const UpdateEventInput(
          eventId: EventId('missing'),
          workspaceId: _ws,
          title: 'X',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<CalendarException>());
    });
  });
}
