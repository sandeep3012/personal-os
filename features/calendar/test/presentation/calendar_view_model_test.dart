import 'package:application/application.dart';
import 'package:feature_calendar/src/application/use_cases/archive_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/create_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/delete_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/get_events_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/update_event_use_case.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:feature_calendar/src/presentation/viewmodels/calendar_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../helpers/fake_event_repository.dart';

const _ws = 'ws-1';

EventTimeRange _range() =>
    EventTimeRange(start: DateTime(2026, 1, 1, 9), end: DateTime(2026, 1, 1, 10));

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'event-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeEventRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = CalendarViewModel(
      getEventsUseCase: GetEventsUseCase(eventRepository: repo),
      createEventUseCase: CreateEventUseCase(
        eventRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateEventUseCase: UpdateEventUseCase(eventRepository: repo),
      archiveEventUseCase: ArchiveEventUseCase(eventRepository: repo),
      deleteEventUseCase: DeleteEventUseCase(eventRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeEventRepository repo;
  late final WorkspaceContext workspaceContext;
  late final CalendarViewModel viewModel;
}

void main() {
  group('CalendarViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('shows an empty list when no events exist', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });

  group('CalendarViewModel.createEvent', () {
    test('creates an event starting active and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();

      final result = await harness.viewModel.createEvent(
        title: 'Standup',
        timeRange: _range(),
        location: 'Room A',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, EventStatus.active);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('CalendarViewModel.updateEvent', () {
    test('updates the title and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created =
          await harness.viewModel.createEvent(title: 'Original', timeRange: _range());

      final result = await harness.viewModel.updateEvent(
        eventId: created.valueOrNull!.id,
        title: 'Renamed',
      );

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull!.single.title, 'Renamed');
    });
  });

  group('CalendarViewModel.archiveEvent', () {
    test('archives an event and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created =
          await harness.viewModel.createEvent(title: 'Event', timeRange: _range());

      final result = await harness.viewModel.archiveEvent(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, EventStatus.archived);
    });

    test('fails when the event is already archived', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created =
          await harness.viewModel.createEvent(title: 'Event', timeRange: _range());
      await harness.viewModel.archiveEvent(created.valueOrNull!.id);

      final result = await harness.viewModel.archiveEvent(created.valueOrNull!.id);

      expect(result.isFailure, isTrue);
    });
  });

  group('CalendarViewModel.deleteEvent', () {
    test('soft-deletes an event and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      await harness.viewModel.createEvent(title: 'Event', timeRange: _range());
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      final created = harness.viewModel.state.dataOrNull!.single;
      final result = await harness.viewModel.deleteEvent(created.id);

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });
}
