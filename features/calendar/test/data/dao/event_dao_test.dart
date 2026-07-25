import 'package:feature_calendar/src/data/dao/event_dao.dart';
import 'package:feature_calendar/src/data/models/event_query_filter.dart';
import 'package:feature_calendar/src/data/models/event_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_event_database_executor.dart';

EventRow _row({
  String id = 'event-1',
  String workspaceId = 'ws-1',
  String status = 'active',
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return EventRow(
    eventId: id,
    workspaceId: workspaceId,
    title: 'Test Event',
    description: 'Some description',
    location: 'Office',
    startTime: DateTime(2024, 1, 2, 9),
    endTime: DateTime(2024, 1, 2, 10),
    status: status,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeEventDatabaseExecutor executor;
  late EventDao dao;

  setUp(() {
    executor = FakeEventDatabaseExecutor();
    dao = EventDao(executor);
  });

  group('EventDao.insert', () {
    test('builds an INSERT statement with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO events'));
      expect(sql, contains('event_id'));
      expect(sql, contains('status'));
    });
  });

  group('EventDao.update', () {
    test('builds an UPDATE statement excluding event_id from SET', () async {
      await dao.update(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE events SET'));
      expect(sql, contains('WHERE event_id = ?'));
    });
  });

  group('EventDao.findById', () {
    test('scopes by event_id, workspace_id, and excludes soft-deleted rows',
        () async {
      await dao.findById('event-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('event_id = ?'));
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('deleted_at IS NULL'));
      expect(executor.executedQueryArgs.single, ['event-1', 'ws-1']);
    });

    test('returns null when no row matches', () async {
      final result = await dao.findById('missing', workspaceId: 'ws-1');
      expect(result, isNull);
    });

    test('maps the returned row', () async {
      executor.queryResults.add([_row(id: 'event-1').toMap()]);
      final result = await dao.findById('event-1', workspaceId: 'ws-1');
      expect(result, isNotNull);
      expect(result!.eventId, 'event-1');
    });
  });

  group('EventDao.findAll', () {
    test('scopes by workspace and orders by created_at ASC', () async {
      await dao.findAll('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('ORDER BY created_at ASC'));
    });
  });

  group('EventDao.findByStatus', () {
    test('scopes by workspace and status', () async {
      await dao.findByStatus('archived', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('status = ?'));
      expect(executor.executedQueryArgs.single, ['ws-1', 'archived']);
    });
  });

  group('EventDao.query', () {
    test('issues a COUNT query and a paginated SELECT', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(const EventQueryFilter(workspaceId: 'ws-1'));

      expect(executor.executedQueries[0], contains('SELECT COUNT(*)'));
      expect(executor.executedQueries[1], contains('LIMIT ? OFFSET ?'));
    });

    test('adds a status filter when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const EventQueryFilter(workspaceId: 'ws-1', status: 'active'),
      );

      expect(executor.executedQueries[0], contains('status = ?'));
    });

    test('adds a title filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const EventQueryFilter(workspaceId: 'ws-1', titleContains: 'meeting'),
      );

      expect(executor.executedQueries[0], contains('LOWER(title) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%meeting%');
    });

    test('adds a location filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const EventQueryFilter(workspaceId: 'ws-1', locationContains: 'office'),
      );

      expect(executor.executedQueries[0], contains('LOWER(location) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%office%');
    });

    test('returns totalCount and mapped items', () async {
      executor.queryResults.add([
        {'total': 2},
      ]);
      executor.queryResults
          .add([_row(id: 'event-a').toMap(), _row(id: 'event-b').toMap()]);

      final result = await dao.query(const EventQueryFilter(workspaceId: 'ws-1'));

      expect(result.totalCount, 2);
      expect(result.items, hasLength(2));
    });
  });

  group('EventDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by event_id and workspace_id',
        () async {
      await dao.softDelete(
        'event-1',
        workspaceId: 'ws-1',
        deletedAt: DateTime(2024, 6, 1),
      );

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?, updated_at = ?'));
      expect(
        executor.executedStatementArgs.single,
        containsAllInOrder([anything, anything, 'event-1', 'ws-1']),
      );
    });
  });

  group('EventDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query scoped by id and workspace',
        () async {
      await dao.exists('event-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
    });

    test('returns true when a row is found', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);
      expect(await dao.exists('event-1', workspaceId: 'ws-1'), isTrue);
    });

    test('returns false when no row is found', () async {
      expect(await dao.exists('event-1', workspaceId: 'ws-1'), isFalse);
    });
  });
}
