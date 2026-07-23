import 'package:feature_tasks/src/application/use_cases/delete_task_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

void main() {
  group('DeleteTaskUseCase', () {
    test('soft-deletes an existing task', () async {
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
      final useCase = DeleteTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const DeleteTaskInput(taskId: TaskId('task-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.store, isEmpty);
    });

    test('is idempotent — deleting a nonexistent task still succeeds',
        () async {
      final repo = FakeTaskRepository();
      final useCase = DeleteTaskUseCase(taskRepository: repo);

      final result = await useCase.execute(
        const DeleteTaskInput(taskId: TaskId('missing'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
