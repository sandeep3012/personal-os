import 'package:feature_calendar/src/application/use_cases/archive_event_use_case.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

Event _existing(EventStatus status) {
  final now = DateTime(2026, 1, 1);
  return Event(
    id: const EventId('event-1'),
    workspaceId: _ws,
    title: 'Event',
    timeRange: EventTimeRange(start: DateTime(2026, 1, 1, 9), end: DateTime(2026, 1, 1, 10)),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ArchiveEventUseCase', () {
    test('archives an active event', () async {
      final repo = FakeEventRepository()..seed([_existing(EventStatus.active)]);
      final useCase = ArchiveEventUseCase(eventRepository: repo);

      final result = await useCase.execute(
        const ArchiveEventInput(eventId: EventId('event-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, EventStatus.archived);
    });

    test('rejects archiving an already-archived event', () async {
      final repo = FakeEventRepository()..seed([_existing(EventStatus.archived)]);
      final useCase = ArchiveEventUseCase(eventRepository: repo);

      final result = await useCase.execute(
        const ArchiveEventInput(eventId: EventId('event-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<CalendarException>());
    });

    test('fails when the event does not exist', () async {
      final repo = FakeEventRepository();
      final useCase = ArchiveEventUseCase(eventRepository: repo);

      final result = await useCase.execute(
        const ArchiveEventInput(eventId: EventId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
