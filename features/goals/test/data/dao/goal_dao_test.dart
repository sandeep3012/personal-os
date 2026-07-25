import 'package:feature_goals/src/data/dao/goal_dao.dart';
import 'package:feature_goals/src/data/models/goal_query_filter.dart';
import 'package:feature_goals/src/data/models/goal_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_goal_database_executor.dart';

GoalRow _row({
  String id = 'goal-1',
  String workspaceId = 'ws-1',
  String status = 'active',
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return GoalRow(
    goalId: id,
    workspaceId: workspaceId,
    name: 'Test Goal',
    targetValue: 10,
    currentProgress: 0,
    status: status,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeGoalDatabaseExecutor executor;
  late GoalDao dao;

  setUp(() {
    executor = FakeGoalDatabaseExecutor();
    dao = GoalDao(executor);
  });

  group('GoalDao.insert', () {
    test('builds an INSERT statement with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO goals'));
      expect(sql, contains('goal_id'));
      expect(sql, contains('status'));
    });
  });

  group('GoalDao.update', () {
    test('builds an UPDATE statement excluding goal_id from SET', () async {
      await dao.update(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE goals SET'));
      expect(sql, contains('WHERE goal_id = ?'));
    });
  });

  group('GoalDao.findById', () {
    test('scopes by goal_id, workspace_id, and excludes soft-deleted rows',
        () async {
      await dao.findById('goal-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('goal_id = ?'));
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('deleted_at IS NULL'));
      expect(executor.executedQueryArgs.single, ['goal-1', 'ws-1']);
    });

    test('returns null when no row matches', () async {
      final result = await dao.findById('missing', workspaceId: 'ws-1');
      expect(result, isNull);
    });

    test('maps the returned row', () async {
      executor.queryResults.add([_row(id: 'goal-1').toMap()]);
      final result = await dao.findById('goal-1', workspaceId: 'ws-1');
      expect(result, isNotNull);
      expect(result!.goalId, 'goal-1');
    });
  });

  group('GoalDao.findAll', () {
    test('scopes by workspace and orders by created_at ASC', () async {
      await dao.findAll('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('ORDER BY created_at ASC'));
    });
  });

  group('GoalDao.findByStatus', () {
    test('scopes by workspace and status', () async {
      await dao.findByStatus('archived', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('status = ?'));
      expect(executor.executedQueryArgs.single, ['ws-1', 'archived']);
    });
  });

  group('GoalDao.query', () {
    test('issues a COUNT query and a paginated SELECT', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(const GoalQueryFilter(workspaceId: 'ws-1'));

      expect(executor.executedQueries[0], contains('SELECT COUNT(*)'));
      expect(executor.executedQueries[1], contains('LIMIT ? OFFSET ?'));
    });

    test('adds a status filter when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const GoalQueryFilter(workspaceId: 'ws-1', status: 'active'),
      );

      expect(executor.executedQueries[0], contains('status = ?'));
    });

    test('adds a name filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const GoalQueryFilter(workspaceId: 'ws-1', nameContains: 'water'),
      );

      expect(executor.executedQueries[0], contains('LOWER(name) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%water%');
    });

    test('returns totalCount and mapped items', () async {
      executor.queryResults.add([
        {'total': 2},
      ]);
      executor.queryResults.add([_row(id: 'goal-a').toMap(), _row(id: 'goal-b').toMap()]);

      final result = await dao.query(const GoalQueryFilter(workspaceId: 'ws-1'));

      expect(result.totalCount, 2);
      expect(result.items, hasLength(2));
    });
  });

  group('GoalDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by goal_id and workspace_id',
        () async {
      await dao.softDelete(
        'goal-1',
        workspaceId: 'ws-1',
        deletedAt: DateTime(2024, 6, 1),
      );

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?, updated_at = ?'));
      expect(
        executor.executedStatementArgs.single,
        containsAllInOrder([anything, anything, 'goal-1', 'ws-1']),
      );
    });
  });

  group('GoalDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query scoped by id and workspace',
        () async {
      await dao.exists('goal-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
    });

    test('returns true when a row is found', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);
      expect(await dao.exists('goal-1', workspaceId: 'ws-1'), isTrue);
    });

    test('returns false when no row is found', () async {
      expect(await dao.exists('goal-1', workspaceId: 'ws-1'), isFalse);
    });
  });
}
