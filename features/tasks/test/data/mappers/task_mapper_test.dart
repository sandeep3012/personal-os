import 'package:feature_tasks/src/data/mappers/task_mapper.dart';
import 'package:feature_tasks/src/data/models/task_row.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_due_date.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TaskMapper();

  Task task({
    String id = 'task-1',
    String title = 'Buy groceries',
    TaskStatus status = TaskStatus.todo,
    String? description,
    TaskDueDate? dueDate,
    DateTime? completedAt,
  }) {
    final now = DateTime(2024, 1, 1, 10, 30);
    return Task(
      id: TaskId(id),
      workspaceId: 'ws-1',
      title: title,
      status: status,
      description: description,
      dueDate: dueDate,
      completedAt: completedAt,
      createdAt: now,
      updatedAt: DateTime(2024, 2, 1, 8),
    );
  }

  group('TaskMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(task(id: 'task-1', title: 'Buy groceries'));

      expect(row.taskId, 'task-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.title, 'Buy groceries');
      expect(row.status, 'todo');
    });

    test('maps every TaskStatus to its enum name', () {
      for (final status in TaskStatus.values) {
        final row = mapper.toRow(task(status: status));
        expect(row.status, status.name);
      }
    });

    test('maps dueDate to its underlying DateTime', () {
      final dueDate = TaskDueDate(DateTime(2026, 3, 1));
      final row = mapper.toRow(task(dueDate: dueDate));
      expect(row.dueDate, DateTime(2026, 3, 1));
    });

    test('maps a null dueDate to null', () {
      final row = mapper.toRow(task());
      expect(row.dueDate, isNull);
    });

    test('always maps deletedAt to null (domain Task is never soft-deleted)',
        () {
      final row = mapper.toRow(task());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode titles', () {
      final row = mapper.toRow(task(title: 'Café run ☕ 買い物'));
      expect(row.title, 'Café run ☕ 買い物');
    });
  });

  group('TaskMapper.toEntity', () {
    TaskRow row({
      String id = 'task-1',
      String title = 'Buy groceries',
      String status = 'todo',
      DateTime? dueDate,
      DateTime? completedAt,
    }) {
      final now = DateTime(2024, 1, 1, 10, 30);
      return TaskRow(
        taskId: id,
        workspaceId: 'ws-1',
        title: title,
        status: status,
        dueDate: dueDate,
        completedAt: completedAt,
        createdAt: now,
        updatedAt: DateTime(2024, 2, 1, 8),
      );
    }

    test('maps all scalar fields', () {
      final task = mapper.toEntity(row(id: 'task-2', title: 'Pay rent'));

      expect(task.id, const TaskId('task-2'));
      expect(task.workspaceId, 'ws-1');
      expect(task.title, 'Pay rent');
    });

    test('converts every status column value back to its enum', () {
      for (final status in TaskStatus.values) {
        final task = mapper.toEntity(row(status: status.name));
        expect(task.status, status);
      }
    });

    test('throws TasksException for an unrecognized status value', () {
      expect(
        () => mapper.toEntity(row(status: 'not_a_real_status')),
        throwsA(isA<TasksException>()),
      );
    });

    test('wraps a non-null dueDate column in TaskDueDate', () {
      final task = mapper.toEntity(row(dueDate: DateTime(2026, 3, 1)));
      expect(task.dueDate, TaskDueDate(DateTime(2026, 3, 1)));
    });

    test('leaves dueDate null when the column is null', () {
      final task = mapper.toEntity(row());
      expect(task.dueDate, isNull);
    });
  });

  group('TaskMapper round-trip', () {
    test('Task -> TaskRow -> Task preserves all domain fields', () {
      final original = task(
        id: 'task-rt',
        title: 'Round Trip',
        status: TaskStatus.inProgress,
        description: 'Some details',
        dueDate: TaskDueDate(DateTime(2026, 5, 1)),
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.title, original.title);
      expect(restored.status, original.status);
      expect(restored.description, original.description);
      expect(restored.dueDate, original.dueDate);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trips a completed task with completedAt', () {
      final completedAt = DateTime(2026, 1, 10);
      final original = task(status: TaskStatus.completed, completedAt: completedAt);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.completedAt, completedAt);
    });
  });
}
