import 'package:feature_tasks/src/data/dao/task_dao.dart';
import 'package:feature_tasks/src/data/models/task_query_filter.dart';
import 'package:feature_tasks/src/data/models/task_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_task_database_executor.dart';

TaskRow _row({
  String id = 'task-1',
  String workspaceId = 'ws-1',
  String status = 'todo',
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return TaskRow(
    taskId: id,
    workspaceId: workspaceId,
    title: 'Test Task',
    status: status,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeTaskDatabaseExecutor executor;
  late TaskDao dao;

  setUp(() {
    executor = FakeTaskDatabaseExecutor();
    dao = TaskDao(executor);
  });

  group('TaskDao.insert', () {
    test('builds an INSERT statement with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO tasks'));
      expect(sql, contains('task_id'));
      expect(sql, contains('status'));
    });
  });

  group('TaskDao.update', () {
    test('builds an UPDATE statement excluding task_id from SET', () async {
      await dao.update(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE tasks SET'));
      expect(sql, contains('WHERE task_id = ?'));
    });
  });

  group('TaskDao.findById', () {
    test('scopes by task_id, workspace_id, and excludes soft-deleted rows',
        () async {
      await dao.findById('task-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('task_id = ?'));
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('deleted_at IS NULL'));
      expect(executor.executedQueryArgs.single, ['task-1', 'ws-1']);
    });

    test('returns null when no row matches', () async {
      final result = await dao.findById('missing', workspaceId: 'ws-1');
      expect(result, isNull);
    });

    test('maps the returned row', () async {
      executor.queryResults.add([_row(id: 'task-1').toMap()]);
      final result = await dao.findById('task-1', workspaceId: 'ws-1');
      expect(result, isNotNull);
      expect(result!.taskId, 'task-1');
    });
  });

  group('TaskDao.findAll', () {
    test('scopes by workspace and orders by created_at ASC', () async {
      await dao.findAll('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('ORDER BY created_at ASC'));
    });
  });

  group('TaskDao.findByStatus', () {
    test('scopes by workspace and status', () async {
      await dao.findByStatus('completed', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('status = ?'));
      expect(executor.executedQueryArgs.single, ['ws-1', 'completed']);
    });
  });

  group('TaskDao.query', () {
    test('issues a COUNT query and a paginated SELECT', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(const TaskQueryFilter(workspaceId: 'ws-1'));

      expect(executor.executedQueries[0], contains('SELECT COUNT(*)'));
      expect(executor.executedQueries[1], contains('LIMIT ? OFFSET ?'));
    });

    test('adds a status filter when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const TaskQueryFilter(workspaceId: 'ws-1', status: 'todo'),
      );

      expect(executor.executedQueries[0], contains('status = ?'));
    });

    test('adds a title filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const TaskQueryFilter(workspaceId: 'ws-1', titleContains: 'groceries'),
      );

      expect(executor.executedQueries[0], contains('LOWER(title) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%groceries%');
    });

    test('returns totalCount and mapped items', () async {
      executor.queryResults.add([
        {'total': 2},
      ]);
      executor.queryResults.add([_row(id: 'task-a').toMap(), _row(id: 'task-b').toMap()]);

      final result = await dao.query(const TaskQueryFilter(workspaceId: 'ws-1'));

      expect(result.totalCount, 2);
      expect(result.items, hasLength(2));
    });
  });

  group('TaskDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by task_id and workspace_id',
        () async {
      await dao.softDelete(
        'task-1',
        workspaceId: 'ws-1',
        deletedAt: DateTime(2024, 6, 1),
      );

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?, updated_at = ?'));
      expect(
        executor.executedStatementArgs.single,
        containsAllInOrder([anything, anything, 'task-1', 'ws-1']),
      );
    });
  });

  group('TaskDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query scoped by id and workspace',
        () async {
      await dao.exists('task-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
    });

    test('returns true when a row is found', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);
      expect(await dao.exists('task-1', workspaceId: 'ws-1'), isTrue);
    });

    test('returns false when no row is found', () async {
      expect(await dao.exists('task-1', workspaceId: 'ws-1'), isFalse);
    });
  });
}
