import 'package:feature_tasks/src/application/use_cases/get_task_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

void main() {
  group('GetTaskUseCase', () {
    test('returns the task when it exists', () async {
      final now = DateTime(2026, 1, 1);
      final task = Task(
        id: const TaskId('task-1'),
        workspaceId: _ws,
        title: 'Task',
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
      );
      final repo = FakeTaskRepository()..seed([task]);
      final useCase = GetTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const GetTaskInput(taskId: TaskId('task-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'Task');
    });

    test('fails when the task does not exist', () async {
      final repo = FakeTaskRepository();
      final useCase = GetTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const GetTaskInput(taskId: TaskId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });
  });
}
