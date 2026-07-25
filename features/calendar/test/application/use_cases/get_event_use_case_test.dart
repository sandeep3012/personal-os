import 'package:feature_calendar/src/application/use_cases/get_event_use_case.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

void main() {
  group('GetEventUseCase', () {
    test('returns the event when it exists', () async {
      final now = DateTime(2026, 1, 1);
      final event = Event(
        id: const EventId('event-1'),
        workspaceId: _ws,
        title: 'Event',
        timeRange:
            EventTimeRange(start: DateTime(2026, 1, 1, 9), end: DateTime(2026, 1, 1, 10)),
        status: EventStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final repo = FakeEventRepository()..seed([event]);
      final useCase = GetEventUseCase(eventRepository: repo);

      final result = await useCase.execute(
        const GetEventInput(eventId: EventId('event-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'Event');
    });

    test('fails when the event does not exist', () async {
      final repo = FakeEventRepository();
      final useCase = GetEventUseCase(eventRepository: repo);

      final result = await useCase.execute(
        const GetEventInput(eventId: EventId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<CalendarException>());
    });
  });
}
