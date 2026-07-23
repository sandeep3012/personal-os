import 'package:application/application.dart';
import 'package:feature_tasks/src/application/use_cases/archive_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/complete_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/create_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/delete_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/get_tasks_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/update_task_use_case.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:feature_tasks/src/presentation/viewmodels/tasks_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'task-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeTaskRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = TasksViewModel(
      getTasksUseCase: GetTasksUseCase(taskRepository: repo),
      createTaskUseCase: CreateTaskUseCase(
        taskRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateTaskUseCase: UpdateTaskUseCase(taskRepository: repo),
      completeTaskUseCase: CompleteTaskUseCase(taskRepository: repo),
      archiveTaskUseCase: ArchiveTaskUseCase(taskRepository: repo),
      deleteTaskUseCase: DeleteTaskUseCase(taskRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeTaskRepository repo;
  late final WorkspaceContext workspaceContext;
  late final TasksViewModel viewModel;
}

void main() {
  group('TasksViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('shows an empty list when no tasks exist', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      // Should not throw — the ViewModel unsubscribed from WorkspaceContext
      // in dispose(), so this switch must not touch a disposed ChangeNotifier.
      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });

  group('TasksViewModel.createTask', () {
    test('creates a task starting at todo and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();

      final result = await harness.viewModel.createTask(title: 'Buy milk');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, TaskStatus.todo);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('TasksViewModel.updateTask', () {
    test('updates the title and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createTask(title: 'Original');

      final result = await harness.viewModel.updateTask(
        taskId: created.valueOrNull!.id,
        title: 'Renamed',
      );

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull!.single.title, 'Renamed');
    });
  });

  group('TasksViewModel.completeTask', () {
    test('marks a task completed and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createTask(title: 'Task');

      final result = await harness.viewModel.completeTask(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, TaskStatus.completed);
    });

    test('fails when the transition is not legal', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createTask(title: 'Task');
      await harness.viewModel.archiveTask(created.valueOrNull!.id);

      final result = await harness.viewModel.completeTask(created.valueOrNull!.id);

      expect(result.isFailure, isTrue);
    });
  });

  group('TasksViewModel.archiveTask', () {
    test('archives a task and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createTask(title: 'Task');

      final result = await harness.viewModel.archiveTask(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, TaskStatus.archived);
    });
  });

  group('TasksViewModel.deleteTask', () {
    test('soft-deletes a task and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createTask(title: 'Task');
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      final result = await harness.viewModel.deleteTask(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });
}
