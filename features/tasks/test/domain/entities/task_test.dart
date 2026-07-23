import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

Task _task({
  TaskStatus status = TaskStatus.todo,
  DateTime? completedAt,
  String title = 'Buy groceries',
}) {
  final now = DateTime(2026, 1, 1);
  return Task(
    id: const TaskId('task-1'),
    workspaceId: _ws,
    title: title,
    status: status,
    completedAt: completedAt,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Task construction', () {
    test('throws when title is empty', () {
      expect(
        () => _task(title: ''),
        throwsA(isA<TasksException>()),
      );
    });

    test('throws when title is only whitespace', () {
      expect(
        () => _task(title: '   '),
        throwsA(isA<TasksException>()),
      );
    });

    test('throws when title exceeds 200 characters', () {
      expect(
        () => _task(title: 'a' * 201),
        throwsA(isA<TasksException>()),
      );
    });

    test('accepts a title at exactly 200 characters', () {
      expect(() => _task(title: 'a' * 200), returnsNormally);
    });
  });

  group('Task.transitionTo — allowed transitions', () {
    test('todo -> in_progress', () {
      final task = _task();
      final result = task.transitionTo(TaskStatus.inProgress, now: DateTime(2026, 1, 2));
      expect(result.status, TaskStatus.inProgress);
      expect(result.completedAt, isNull);
    });

    test('todo -> completed sets completedAt', () {
      final task = _task();
      final now = DateTime(2026, 1, 2);
      final result = task.transitionTo(TaskStatus.completed, now: now);
      expect(result.status, TaskStatus.completed);
      expect(result.completedAt, now);
    });

    test('todo -> archived directly (skipping completion) leaves completedAt null', () {
      final task = _task();
      final result = task.transitionTo(TaskStatus.archived, now: DateTime(2026, 1, 2));
      expect(result.status, TaskStatus.archived);
      expect(result.completedAt, isNull);
    });

    test('in_progress -> completed sets completedAt', () {
      final task = _task(status: TaskStatus.inProgress);
      final now = DateTime(2026, 1, 2);
      final result = task.transitionTo(TaskStatus.completed, now: now);
      expect(result.completedAt, now);
    });

    test('in_progress -> archived', () {
      final task = _task(status: TaskStatus.inProgress);
      final result = task.transitionTo(TaskStatus.archived, now: DateTime(2026, 1, 2));
      expect(result.status, TaskStatus.archived);
    });

    test('completed -> archived retains the original completedAt', () {
      final completedAt = DateTime(2026, 1, 1, 10);
      final task = _task(status: TaskStatus.completed, completedAt: completedAt);
      final result = task.transitionTo(TaskStatus.archived, now: DateTime(2026, 1, 5));
      expect(result.status, TaskStatus.archived);
      expect(result.completedAt, completedAt);
    });
  });

  group('Task.transitionTo — rejected transitions', () {
    test('archived cannot transition anywhere (terminal)', () {
      final task = _task(status: TaskStatus.archived);
      expect(
        () => task.transitionTo(TaskStatus.todo, now: DateTime(2026, 1, 2)),
        throwsA(isA<TasksException>()),
      );
    });

    test('completed cannot reopen to in_progress', () {
      final task = _task(status: TaskStatus.completed);
      expect(
        () => task.transitionTo(TaskStatus.inProgress, now: DateTime(2026, 1, 2)),
        throwsA(isA<TasksException>()),
      );
    });

    test('completed cannot reopen to todo', () {
      final task = _task(status: TaskStatus.completed);
      expect(
        () => task.transitionTo(TaskStatus.todo, now: DateTime(2026, 1, 2)),
        throwsA(isA<TasksException>()),
      );
    });

    test('cannot transition to the same status', () {
      final task = _task();
      expect(
        () => task.transitionTo(TaskStatus.todo, now: DateTime(2026, 1, 2)),
        throwsA(isA<TasksException>()),
      );
    });
  });

  group('Task.copyWith', () {
    test('does not change status', () {
      final task = _task(status: TaskStatus.inProgress);
      final updated = task.copyWith(title: 'Renamed');
      expect(updated.status, TaskStatus.inProgress);
      expect(updated.title, 'Renamed');
    });
  });

  group('Task equality', () {
    test('two tasks with the same id are equal regardless of other fields', () {
      final now = DateTime(2026, 1, 1);
      final a = Task(
        id: const TaskId('task-1'),
        workspaceId: _ws,
        title: 'A',
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
      );
      final b = Task(
        id: const TaskId('task-1'),
        workspaceId: _ws,
        title: 'B',
        status: TaskStatus.completed,
        createdAt: now,
        updatedAt: now,
      );
      expect(a, b);
    });
  });
}
