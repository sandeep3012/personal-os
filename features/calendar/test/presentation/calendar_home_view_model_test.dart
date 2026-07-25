import 'package:application/application.dart';
import 'package:feature_calendar/src/application/use_cases/get_events_use_case.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:feature_calendar/src/presentation/viewmodels/calendar_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

Event _event(
  String id, {
  EventStatus status = EventStatus.active,
  DateTime? start,
}) {
  final now = DateTime(2026, 1, 1);
  return Event(
    id: EventId(id),
    workspaceId: _ws,
    title: 'Event $id',
    timeRange: EventTimeRange(
      start: start ?? DateTime(2026, 6, 1, 9),
      end: (start ?? DateTime(2026, 6, 1, 9)).add(const Duration(hours: 1)),
    ),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

final class _Harness {
  _Harness() : repo = FakeEventRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = CalendarHomeViewModel(
      getEventsUseCase: GetEventsUseCase(eventRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeEventRepository repo;
  late final WorkspaceContext workspaceContext;
  late final CalendarHomeViewModel viewModel;
}

void main() {
  group('CalendarHomeViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('upcomingCount counts only active events starting now or later',
        () async {
      final harness = _Harness()
        ..repo.seed([
          _event('e1', status: EventStatus.active, start: DateTime(2026, 6, 1)),
          _event('e2', status: EventStatus.active, start: DateTime(2020, 1, 1)),
          _event('e3', status: EventStatus.archived, start: DateTime(2026, 6, 1)),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.upcomingCount, 1);
    });

    test('archivedCount counts only archived events', () async {
      final harness = _Harness()
        ..repo.seed([
          _event('e1', status: EventStatus.archived),
          _event('e2', status: EventStatus.archived),
          _event('e3', status: EventStatus.active),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.archivedCount, 2);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });
}
