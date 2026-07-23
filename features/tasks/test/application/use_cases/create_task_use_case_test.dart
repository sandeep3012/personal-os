import 'package:feature_tasks/src/application/use_cases/create_task_use_case.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_due_date.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../../helpers/fake_task_repository.dart';

final class _FixedIdGenerator implements IdGenerator {
  int _i = 0;
  @override
  String generate() => 'task-${++_i}';
}

void main() {
  late FakeTaskRepository repo;
  late CreateTaskUseCase useCase;

  setUp(() {
    repo = FakeTaskRepository();
    useCase = CreateTaskUseCase(
      taskRepository: repo,
      idGenerator: _FixedIdGenerator(),
    );
  });

  group('CreateTaskUseCase', () {
    test('creates and persists a task starting at todo', () async {
      final result = await useCase.execute(
        const CreateTaskInput(workspaceId: 'ws-1', title: 'Buy groceries'),
      );

      expect(result.isSuccess, isTrue);
      final task = result.valueOrNull!;
      expect(task.title, 'Buy groceries');
      expect(task.status, TaskStatus.todo);
      expect(repo.store, contains(task));
    });

    test('returns generated id for the new task', () async {
      final result = await useCase.execute(
        const CreateTaskInput(workspaceId: 'ws-1', title: 'Task'),
      );

      expect(result.valueOrNull!.id.value, 'task-1');
    });

    test('accepts an optional description and due date', () async {
      final dueDate = TaskDueDate(DateTime(2026, 3, 1));
      final result = await useCase.execute(
        CreateTaskInput(
          workspaceId: 'ws-1',
          title: 'Task',
          description: 'Details',
          dueDate: dueDate,
        ),
      );

      expect(result.valueOrNull!.description, 'Details');
      expect(result.valueOrNull!.dueDate, dueDate);
    });

    test('rejects a description longer than 1000 characters', () async {
      final result = await useCase.execute(
        CreateTaskInput(
          workspaceId: 'ws-1',
          title: 'Task',
          description: 'a' * 1001,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });

    test('rejects an empty title (entity invariant)', () async {
      final result = await useCase.execute(
        const CreateTaskInput(workspaceId: 'ws-1', title: ''),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TasksException>());
    });
  });
}
