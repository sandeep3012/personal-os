import 'package:feature_tasks/src/application/use_cases/archive_task_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

Task _existing(TaskStatus status) {
  final now = DateTime(2026, 1, 1);
  return Task(
    id: const TaskId('task-1'),
    workspaceId: _ws,
    title: 'Task',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ArchiveTaskUseCase', () {
    test('archives a todo task', () async {
      final repo = FakeTaskRepository()..seed([_existing(TaskStatus.todo)]);
      final useCase = ArchiveTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const ArchiveTaskInput(taskId: TaskId('task-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, TaskStatus.archived);
    });

    test('archives a completed task, retaining completedAt', () async {
      final now = DateTime(2026, 1, 1);
      final completed = Task(
        id: const TaskId('task-1'),
        workspaceId: _ws,
        title: 'Task',
        status: TaskStatus.completed,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final repo = FakeTaskRepository()..seed([completed]);
      final useCase = ArchiveTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const ArchiveTaskInput(taskId: TaskId('task-1'), workspaceId: _ws),
      );

      expect(result.valueOrNull!.status, TaskStatus.archived);
      expect(result.valueOrNull!.completedAt, now);
    });

    test('rejects archiving an already-archived task', () async {
      final repo = FakeTaskRepository()..seed([_existing(TaskStatus.archived)]);
      final useCase = ArchiveTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const ArchiveTaskInput(taskId: TaskId('task-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });

    test('fails when the task does not exist', () async {
      final repo = FakeTaskRepository();
      final useCase = ArchiveTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const ArchiveTaskInput(taskId: TaskId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
