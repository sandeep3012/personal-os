import 'package:feature_habits/src/data/dao/habit_dao.dart';
import 'package:feature_habits/src/data/models/habit_query_filter.dart';
import 'package:feature_habits/src/data/models/habit_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_habit_database_executor.dart';

HabitRow _row({
  String id = 'habit-1',
  String workspaceId = 'ws-1',
  String status = 'active',
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return HabitRow(
    habitId: id,
    workspaceId: workspaceId,
    name: 'Test Habit',
    frequency: 'daily',
    status: status,
    currentStreak: 0,
    longestStreak: 0,
    completionLog: const [],
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeHabitDatabaseExecutor executor;
  late HabitDao dao;

  setUp(() {
    executor = FakeHabitDatabaseExecutor();
    dao = HabitDao(executor);
  });

  group('HabitDao.insert', () {
    test('builds an INSERT statement with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO habits'));
      expect(sql, contains('habit_id'));
      expect(sql, contains('status'));
    });
  });

  group('HabitDao.update', () {
    test('builds an UPDATE statement excluding habit_id from SET', () async {
      await dao.update(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE habits SET'));
      expect(sql, contains('WHERE habit_id = ?'));
    });
  });

  group('HabitDao.findById', () {
    test('scopes by habit_id, workspace_id, and excludes soft-deleted rows',
        () async {
      await dao.findById('habit-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('habit_id = ?'));
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('deleted_at IS NULL'));
      expect(executor.executedQueryArgs.single, ['habit-1', 'ws-1']);
    });

    test('returns null when no row matches', () async {
      final result = await dao.findById('missing', workspaceId: 'ws-1');
      expect(result, isNull);
    });

    test('maps the returned row', () async {
      executor.queryResults.add([_row(id: 'habit-1').toMap()]);
      final result = await dao.findById('habit-1', workspaceId: 'ws-1');
      expect(result, isNotNull);
      expect(result!.habitId, 'habit-1');
    });
  });

  group('HabitDao.findAll', () {
    test('scopes by workspace and orders by created_at ASC', () async {
      await dao.findAll('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('ORDER BY created_at ASC'));
    });
  });

  group('HabitDao.findByStatus', () {
    test('scopes by workspace and status', () async {
      await dao.findByStatus('archived', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('status = ?'));
      expect(executor.executedQueryArgs.single, ['ws-1', 'archived']);
    });
  });

  group('HabitDao.query', () {
    test('issues a COUNT query and a paginated SELECT', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(const HabitQueryFilter(workspaceId: 'ws-1'));

      expect(executor.executedQueries[0], contains('SELECT COUNT(*)'));
      expect(executor.executedQueries[1], contains('LIMIT ? OFFSET ?'));
    });

    test('adds a status filter when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const HabitQueryFilter(workspaceId: 'ws-1', status: 'active'),
      );

      expect(executor.executedQueries[0], contains('status = ?'));
    });

    test('adds a name filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const HabitQueryFilter(workspaceId: 'ws-1', nameContains: 'water'),
      );

      expect(executor.executedQueries[0], contains('LOWER(name) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%water%');
    });

    test('returns totalCount and mapped items', () async {
      executor.queryResults.add([
        {'total': 2},
      ]);
      executor.queryResults.add([_row(id: 'habit-a').toMap(), _row(id: 'habit-b').toMap()]);

      final result = await dao.query(const HabitQueryFilter(workspaceId: 'ws-1'));

      expect(result.totalCount, 2);
      expect(result.items, hasLength(2));
    });
  });

  group('HabitDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by habit_id and workspace_id',
        () async {
      await dao.softDelete(
        'habit-1',
        workspaceId: 'ws-1',
        deletedAt: DateTime(2024, 6, 1),
      );

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?, updated_at = ?'));
      expect(
        executor.executedStatementArgs.single,
        containsAllInOrder([anything, anything, 'habit-1', 'ws-1']),
      );
    });
  });

  group('HabitDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query scoped by id and workspace',
        () async {
      await dao.exists('habit-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
    });

    test('returns true when a row is found', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);
      expect(await dao.exists('habit-1', workspaceId: 'ws-1'), isTrue);
    });

    test('returns false when no row is found', () async {
      expect(await dao.exists('habit-1', workspaceId: 'ws-1'), isFalse);
    });
  });
}
