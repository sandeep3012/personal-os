import 'package:feature_calendar/src/application/use_cases/search_events_use_case.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_query.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

Event _event(String id, String title, EventStatus status) {
  final now = DateTime(2026, 1, 1);
  return Event(
    id: EventId(id),
    workspaceId: _ws,
    title: title,
    timeRange: EventTimeRange(start: DateTime(2026, 1, 1, 9), end: DateTime(2026, 1, 1, 10)),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeEventRepository repo;
  late SearchEventsUseCase useCase;

  setUp(() {
    repo = FakeEventRepository()
      ..seed([
        _event('t1', 'Team standup', EventStatus.active),
        _event('t2', 'Old review', EventStatus.archived),
        _event('t3', 'Team retro', EventStatus.active),
      ]);
    useCase = SearchEventsUseCase(eventRepository: repo);
  });

  group('SearchEventsUseCase', () {
    test('filters by status', () async {
      final result = await useCase.execute(
        const EventQuery(workspaceId: _ws, status: EventStatus.active),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 2);
    });

    test('filters by title (case-insensitive contains)', () async {
      final result = await useCase.execute(
        const EventQuery(workspaceId: _ws, titleContains: 'team'),
      );

      expect(result.valueOrNull!.items, hasLength(2));
    });

    test('paginates results', () async {
      final result = await useCase.execute(
        const EventQuery(workspaceId: _ws, pageSize: 2, pageIndex: 0),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 3);
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });
  });
}
