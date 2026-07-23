import 'package:feature_tasks/src/domain/events/task_archived_event.dart';
import 'package:feature_tasks/src/domain/events/task_completed_event.dart';
import 'package:feature_tasks/src/domain/events/task_created_event.dart';
import 'package:feature_tasks/src/domain/events/task_deleted_event.dart';
import 'package:feature_tasks/src/domain/events/task_updated_event.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

void main() {
  group('TaskCreatedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 1);
      final event = TaskCreatedEvent(
        taskId: const TaskId('task-1'),
        workspaceId: _ws,
        title: 'Buy groceries',
        status: TaskStatus.todo,
        timestamp: timestamp,
      );

      expect(event.taskId, const TaskId('task-1'));
      expect(event.workspaceId, _ws);
      expect(event.title, 'Buy groceries');
      expect(event.status, TaskStatus.todo);
      expect(event.timestamp, timestamp);
    });
  });

  group('TaskUpdatedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 2);
      final event = TaskUpdatedEvent(
        taskId: const TaskId('task-1'),
        workspaceId: _ws,
        title: 'Renamed',
        status: TaskStatus.inProgress,
        timestamp: timestamp,
      );

      expect(event.title, 'Renamed');
      expect(event.status, TaskStatus.inProgress);
      expect(event.timestamp, timestamp);
    });
  });

  group('TaskCompletedEvent', () {
    test('holds all constructor fields', () {
      final completedAt = DateTime(2026, 1, 3);
      final timestamp = DateTime(2026, 1, 3);
      final event = TaskCompletedEvent(
        taskId: const TaskId('task-1'),
        workspaceId: _ws,
        completedAt: completedAt,
        timestamp: timestamp,
      );

      expect(event.completedAt, completedAt);
      expect(event.timestamp, timestamp);
    });
  });

  group('TaskArchivedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 4);
      final event = TaskArchivedEvent(
        taskId: const TaskId('task-1'),
        workspaceId: _ws,
        timestamp: timestamp,
      );

      expect(event.taskId, const TaskId('task-1'));
      expect(event.workspaceId, _ws);
      expect(event.timestamp, timestamp);
    });
  });

  group('TaskDeletedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 5);
      final event = TaskDeletedEvent(
        taskId: const TaskId('task-1'),
        workspaceId: _ws,
        timestamp: timestamp,
      );

      expect(event.taskId, const TaskId('task-1'));
      expect(event.workspaceId, _ws);
      expect(event.timestamp, timestamp);
    });
  });
}
