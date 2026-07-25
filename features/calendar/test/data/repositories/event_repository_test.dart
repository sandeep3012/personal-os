import 'package:feature_calendar/src/data/dao/event_dao.dart';
import 'package:feature_calendar/src/data/mappers/event_mapper.dart';
import 'package:feature_calendar/src/data/models/event_row.dart';
import 'package:feature_calendar/src/data/repositories/event_repository.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_query.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dao/fake_event_database_executor.dart';

// Mirrors Notes' note_repository_test.dart: exercises EventRepository
// against the real EventDao and EventMapper, with the fake at the
// FakeEventDatabaseExecutor boundary.

EventRow _row({
  String id = 'event-1',
  String workspaceId = 'ws-1',
  String title = 'Standup',
}) {
  final now = DateTime(2024, 1, 1);
  return EventRow(
    eventId: id,
    workspaceId: workspaceId,
    title: title,
    description: 'Daily sync',
    startTime: DateTime(2024, 1, 2, 9),
    endTime: DateTime(2024, 1, 2, 10),
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

Event _event({String id = 'event-1', String workspaceId = 'ws-1'}) {
  final now = DateTime(2024, 1, 1);
  return Event(
    id: EventId(id),
    workspaceId: workspaceId,
    title: 'Standup',
    timeRange: EventTimeRange(
      start: DateTime(2024, 1, 2, 9),
      end: DateTime(2024, 1, 2, 10),
    ),
    status: EventStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeEventDatabaseExecutor executor;
  late EventRepository repository;

  setUp(() {
    executor = FakeEventDatabaseExecutor();
    repository = EventRepository(
      eventDao: EventDao(executor),
      eventMapper: const EventMapper(),
    );
  });

  group('EventRepository.findById', () {
    test('returns a correctly mapped Event when the row exists', () async {
      executor.queryResults.add([_row(id: 'event-1', title: 'My Event').toMap()]);

      final result =
          await repository.findById(const EventId('event-1'), workspaceId: 'ws-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'My Event');
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const EventId('missing'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure into a CalendarException', () async {
      executor.queryError = Exception('disk read error');

      final result = await repository.findById(
        const EventId('event-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<CalendarException>());
      expect(result.exceptionOrNull!.message, contains('disk read error'));
    });

    test('passes through a CalendarException raised by the mapper unchanged',
        () async {
      final corruptRow = _row(id: 'event-1').toMap();
      corruptRow['status'] = 'not_a_real_status';
      executor.queryResults.add([corruptRow]);

      final result = await repository.findById(
        const EventId('event-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull!.message, contains('Unrecognized status'));
    });
  });

  group('EventRepository.findAll', () {
    test('maps all rows', () async {
      executor.queryResults.add([
        _row(id: 'event-a', title: 'A').toMap(),
        _row(id: 'event-b', title: 'B').toMap(),
      ]);

      final result = await repository.findAll(workspaceId: 'ws-1');

      expect(result.valueOrNull!.map((e) => e.title), ['A', 'B']);
    });

    test('returns an empty list, not a failure, when no events exist', () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });

  group('EventRepository.findByStatus', () {
    test('scopes the DAO call by status', () async {
      executor.queryResults.add([_row(id: 'event-1').toMap()]);

      final result = await repository.findByStatus(
        EventStatus.active,
        workspaceId: 'ws-1',
      );

      expect(executor.executedQueryArgs.single, ['ws-1', 'active']);
      expect(result.valueOrNull, hasLength(1));
    });
  });

  group('EventRepository.search', () {
    test('maps the DAO query result into an EventPage', () async {
      executor.queryResults.add([
        {'total': 1},
      ]);
      executor.queryResults.add([_row(id: 'event-1').toMap()]);

      final result = await repository.search(
        const EventQuery(workspaceId: 'ws-1'),
      );

      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items, hasLength(1));
    });
  });

  group('EventRepository.save', () {
    test('inserts a new event when it does not already exist', () async {
      final result = await repository.save(_event(id: 'event-new'));

      expect(result.isSuccess, isTrue);
      final insertSql =
          executor.executedStatements.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO events'));
    });

    test('updates an existing event instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      final result = await repository.save(_event(id: 'event-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql =
          executor.executedStatements.firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE events SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('write failed');
      final result = await repository.save(_event());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<CalendarException>());
    });
  });

  group('EventRepository.softDelete', () {
    test('delegates directly to EventDao.softDelete', () async {
      final result = await repository.softDelete(
        const EventId('event-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const EventId('event-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<CalendarException>());
    });
  });
}
