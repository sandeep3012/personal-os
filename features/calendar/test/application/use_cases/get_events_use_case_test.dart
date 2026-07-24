import 'package:feature_calendar/src/application/use_cases/get_events_use_case.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

Event _event(String id, EventStatus status) {
  final now = DateTime(2026, 1, 1);
  return Event(
    id: EventId(id),
    workspaceId: _ws,
    title: 'Event $id',
    timeRange: EventTimeRange(start: DateTime(2026, 1, 1, 9), end: DateTime(2026, 1, 1, 10)),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GetEventsUseCase', () {
    test('returns an empty list when no events exist', () async {
      final repo = FakeEventRepository();
      final useCase = GetEventsUseCase(eventRepository: repo);

      final result = await useCase.execute(const GetEventsInput(workspaceId: _ws));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all events regardless of status, including archived',
        () async {
      final repo = FakeEventRepository()
        ..seed([
          _event('t1', EventStatus.active),
          _event('t2', EventStatus.active),
          _event('t3', EventStatus.archived),
        ]);
      final useCase = GetEventsUseCase(eventRepository: repo);

      final result = await useCase.execute(const GetEventsInput(workspaceId: _ws));

      expect(result.valueOrNull, hasLength(3));
    });
  });
}
