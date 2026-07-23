import 'package:feature_tasks/src/data/dao/task_dao.dart';
import 'package:feature_tasks/src/data/mappers/task_mapper.dart';
import 'package:feature_tasks/src/data/models/task_row.dart';
import 'package:feature_tasks/src/data/repositories/task_repository.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_query.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dao/fake_task_database_executor.dart';

// Mirrors Finance's account_repository_test.dart: exercises TaskRepository
// against the real TaskDao and TaskMapper, with the fake at the
// FakeTaskDatabaseExecutor boundary.

TaskRow _row({
  String id = 'task-1',
  String workspaceId = 'ws-1',
  String title = 'Buy groceries',
}) {
  final now = DateTime(2024, 1, 1);
  return TaskRow(
    taskId: id,
    workspaceId: workspaceId,
    title: title,
    status: 'todo',
    createdAt: now,
    updatedAt: now,
  );
}

Task _task({String id = 'task-1', String workspaceId = 'ws-1'}) {
  final now = DateTime(2024, 1, 1);
  return Task(
    id: TaskId(id),
    workspaceId: workspaceId,
    title: 'Buy groceries',
    status: TaskStatus.todo,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeTaskDatabaseExecutor executor;
  late TaskRepository repository;

  setUp(() {
    executor = FakeTaskDatabaseExecutor();
    repository = TaskRepository(
      taskDao: TaskDao(executor),
      taskMapper: const TaskMapper(),
    );
  });

  group('TaskRepository.findById', () {
    test('returns a correctly mapped Task when the row exists', () async {
      executor.queryResults.add([_row(id: 'task-1', title: 'My Task').toMap()]);

      final result =
          await repository.findById(const TaskId('task-1'), workspaceId: 'ws-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'My Task');
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const TaskId('missing'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure into a TasksException', () async {
      executor.queryError = Exception('disk read error');

      final result = await repository.findById(
        const TaskId('task-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
      expect(result.exceptionOrNull!.message, contains('disk read error'));
    });

    test('passes through a TasksException raised by the mapper unchanged',
        () async {
      final corruptRow = _row(id: 'task-1').toMap();
      corruptRow['status'] = 'not_a_real_status';
      executor.queryResults.add([corruptRow]);

      final result = await repository.findById(
        const TaskId('task-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull!.message, contains('Unrecognized status'));
    });
  });

  group('TaskRepository.findAll', () {
    test('maps all rows', () async {
      executor.queryResults.add([
        _row(id: 'task-a', title: 'A').toMap(),
        _row(id: 'task-b', title: 'B').toMap(),
      ]);

      final result = await repository.findAll(workspaceId: 'ws-1');

      expect(result.valueOrNull!.map((t) => t.title), ['A', 'B']);
    });

    test('returns an empty list, not a failure, when no tasks exist', () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });

  group('TaskRepository.findByStatus', () {
    test('scopes the DAO call by status', () async {
      executor.queryResults.add([_row(id: 'task-1').toMap()]);

      final result = await repository.findByStatus(
        TaskStatus.todo,
        workspaceId: 'ws-1',
      );

      expect(executor.executedQueryArgs.single, ['ws-1', 'todo']);
      expect(result.valueOrNull, hasLength(1));
    });
  });

  group('TaskRepository.search', () {
    test('maps the DAO query result into a TaskPage', () async {
      executor.queryResults.add([
        {'total': 1},
      ]);
      executor.queryResults.add([_row(id: 'task-1').toMap()]);

      final result = await repository.search(
        const TaskQuery(workspaceId: 'ws-1'),
      );

      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items, hasLength(1));
    });
  });

  group('TaskRepository.save', () {
    test('inserts a new task when it does not already exist', () async {
      final result = await repository.save(_task(id: 'task-new'));

      expect(result.isSuccess, isTrue);
      final insertSql =
          executor.executedStatements.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO tasks'));
    });

    test('updates an existing task instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      final result = await repository.save(_task(id: 'task-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql =
          executor.executedStatements.firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE tasks SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('write failed');
      final result = await repository.save(_task());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });
  });

  group('TaskRepository.softDelete', () {
    test('delegates directly to TaskDao.softDelete', () async {
      final result = await repository.softDelete(
        const TaskId('task-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const TaskId('task-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });
  });
}
