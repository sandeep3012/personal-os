import 'package:feature_calendar/src/application/use_cases/create_event_use_case.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

EventTimeRange _range() => EventTimeRange(
      start: DateTime(2026, 1, 1, 9),
      end: DateTime(2026, 1, 1, 10),
    );

final class _FixedId implements IdGenerator {
  @override
  String generate() => 'event-1';
}

void main() {
  group('CreateEventUseCase', () {
    test('creates an event starting active', () async {
      final repo = FakeEventRepository();
      final useCase = CreateEventUseCase(eventRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        CreateEventInput(workspaceId: _ws, title: 'Standup', timeRange: _range()),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, EventStatus.active);
      expect(result.valueOrNull!.title, 'Standup');
      expect(repo.store, hasLength(1));
    });

    test('creates an event with location and description', () async {
      final repo = FakeEventRepository();
      final useCase = CreateEventUseCase(eventRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        CreateEventInput(
          workspaceId: _ws,
          title: 'Standup',
          timeRange: _range(),
          location: 'Room A',
          description: 'Daily sync',
        ),
      );

      expect(result.valueOrNull!.location, 'Room A');
      expect(result.valueOrNull!.description, 'Daily sync');
    });

    test('rejects an empty title', () async {
      final repo = FakeEventRepository();
      final useCase = CreateEventUseCase(eventRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        CreateEventInput(workspaceId: _ws, title: '   ', timeRange: _range()),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
