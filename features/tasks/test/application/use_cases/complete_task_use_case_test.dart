import 'package:feature_tasks/src/application/use_cases/complete_task_use_case.dart';
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
  group('CompleteTaskUseCase', () {
    test('transitions a todo task to completed and sets completedAt',
        () async {
      final repo = FakeTaskRepository()..seed([_existing(TaskStatus.todo)]);
      final useCase = CompleteTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const CompleteTaskInput(taskId: TaskId('task-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, TaskStatus.completed);
      expect(result.valueOrNull!.completedAt, isNotNull);
    });

    test('rejects completing an already-archived task', () async {
      final repo = FakeTaskRepository()..seed([_existing(TaskStatus.archived)]);
      final useCase = CompleteTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const CompleteTaskInput(taskId: TaskId('task-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });

    test('fails when the task does not exist', () async {
      final repo = FakeTaskRepository();
      final useCase = CompleteTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const CompleteTaskInput(taskId: TaskId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });
  });
}
