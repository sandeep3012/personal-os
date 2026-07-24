import 'package:feature_calendar/src/application/use_cases/delete_event_use_case.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

void main() {
  group('DeleteEventUseCase', () {
    test('soft-deletes an existing event', () async {
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
      final useCase = DeleteEventUseCase(eventRepository: repo);

      final result = await useCase.execute(
        const DeleteEventInput(eventId: EventId('event-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.store, isEmpty);
    });

    test('is idempotent — deleting a nonexistent event still succeeds', () async {
      final repo = FakeEventRepository();
      final useCase = DeleteEventUseCase(eventRepository: repo);

      final result = await useCase.execute(
        const DeleteEventInput(eventId: EventId('missing'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
