import 'package:feature_tasks/src/application/use_cases/get_tasks_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

Task _task(String id, TaskStatus status) {
  final now = DateTime(2026, 1, 1);
  return Task(
    id: TaskId(id),
    workspaceId: _ws,
    title: 'Task $id',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GetTasksUseCase', () {
    test('returns an empty list when no tasks exist', () async {
      final repo = FakeTaskRepository();
      final useCase = GetTasksUseCase(taskRepository: repo);

      final result = await useCase.execute(const GetTasksInput(workspaceId: _ws));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all tasks regardless of status, including archived',
        () async {
      final repo = FakeTaskRepository()
        ..seed([
          _task('t1', TaskStatus.todo),
          _task('t2', TaskStatus.completed),
          _task('t3', TaskStatus.archived),
        ]);
      final useCase = GetTasksUseCase(taskRepository: repo);

      final result = await useCase.execute(const GetTasksInput(workspaceId: _ws));

      expect(result.valueOrNull, hasLength(3));
    });
  });
}
