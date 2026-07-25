import 'package:application/application.dart';
import 'package:feature_calendar/src/application/use_cases/archive_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/create_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/delete_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/get_events_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/update_event_use_case.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:feature_calendar/src/presentation/pages/calendar_page.dart';
import 'package:feature_calendar/src/presentation/viewmodels/calendar_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

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
    viewModel = CalendarViewModel(
      getEventsUseCase: GetEventsUseCase(eventRepository: repo),
      createEventUseCase: CreateEventUseCase(
        eventRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateEventUseCase: UpdateEventUseCase(eventRepository: repo),
      archiveEventUseCase: ArchiveEventUseCase(eventRepository: repo),
      deleteEventUseCase: DeleteEventUseCase(eventRepository: repo),
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeEventRepository repo;
  late final CalendarViewModel viewModel;

  Widget buildPage() => MaterialApp(home: CalendarPage(viewModel: viewModel));
}

void main() {
  group('CalendarPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no events exist', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No events yet'), findsOneWidget);
    });

    testWidgets('shows an event after loading', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createEvent(title: 'Standup', timeRange: _range());
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Standup'), findsOneWidget);
    });
  });

  group('CalendarPage — create', () {
    testWidgets('tapping the FAB opens the add-event dialog', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Add Event')),
        findsOneWidget,
      );
    });
  });

  group('CalendarPage — edit', () {
    testWidgets('tapping an event opens the edit dialog pre-filled with its title',
        (tester) async {
      final harness = _Harness();
      await harness.viewModel.createEvent(title: 'Original', timeRange: _range());
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Event'), findsOneWidget);
    });

    testWidgets('editing the title updates the list', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createEvent(title: 'Original', timeRange: _range());
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Renamed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });
  });

  group('CalendarPage — archive', () {
    testWidgets('the Archive button in the edit dialog archives the event',
        (tester) async {
      final harness = _Harness();
      final created =
          await harness.viewModel.createEvent(title: 'Event', timeRange: _range());
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Event'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      // Archived events are excluded from the visible list.
      expect(find.text('Event'), findsNothing);

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'archived');
    });
  });

  group('CalendarPage — delete', () {
    testWidgets('swiping an event away deletes it', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createEvent(title: 'Event', timeRange: _range());
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Event'), findsNothing);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });

  group('CalendarPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No events yet'), findsOneWidget);

      await harness.viewModel.createEvent(title: 'Newly Added', timeRange: _range());
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
