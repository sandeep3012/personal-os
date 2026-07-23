import 'package:feature_tasks/src/application/use_cases/update_task_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

Task _existing({TaskStatus status = TaskStatus.inProgress}) {
  final now = DateTime(2026, 1, 1);
  return Task(
    id: const TaskId('task-1'),
    workspaceId: _ws,
    title: 'Original title',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeTaskRepository repo;
  late UpdateTaskUseCase useCase;

  setUp(() {
    repo = FakeTaskRepository()..seed([_existing()]);
    useCase = UpdateTaskUseCase(taskRepository: repo);
  });

  group('UpdateTaskUseCase', () {
    test('updates the title', () async {
      final result = await useCase.execute(
        const UpdateTaskInput(
          taskId: TaskId('task-1'),
          workspaceId: _ws,
          title: 'Renamed',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'Renamed');
    });

    test('does not change status', () async {
      final result = await useCase.execute(
        const UpdateTaskInput(
          taskId: TaskId('task-1'),
          workspaceId: _ws,
          title: 'Renamed',
        ),
      );

      expect(result.valueOrNull!.status, TaskStatus.inProgress);
    });

    test('rejects a description longer than 1000 characters', () async {
      final result = await useCase.execute(
        UpdateTaskInput(
          taskId: const TaskId('task-1'),
          workspaceId: _ws,
          description: 'a' * 1001,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });

    test('fails when the task does not exist', () async {
      final result = await useCase.execute(
        const UpdateTaskInput(
          taskId: TaskId('missing'),
          workspaceId: _ws,
          title: 'X',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });
  });
}
