import 'package:application/application.dart';
import 'package:feature_tasks/src/application/use_cases/get_tasks_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:feature_tasks/src/presentation/viewmodels/tasks_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

Task _task(
  String id, {
  TaskStatus status = TaskStatus.todo,
  DateTime? completedAt,
}) {
  final now = DateTime(2026, 1, 1);
  return Task(
    id: TaskId(id),
    workspaceId: _ws,
    title: 'Task $id',
    status: status,
    completedAt: completedAt,
    createdAt: now,
    updatedAt: now,
  );
}

final class _Harness {
  _Harness() : repo = FakeTaskRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = TasksHomeViewModel(
      getTasksUseCase: GetTasksUseCase(taskRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeTaskRepository repo;
  late final WorkspaceContext workspaceContext;
  late final TasksHomeViewModel viewModel;
}

void main() {
  group('TasksHomeViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('activeCount counts only todo and inProgress tasks', () async {
      final now = DateTime.now();
      final harness = _Harness()
        ..repo.seed([
          _task('t1', status: TaskStatus.todo),
          _task('t2', status: TaskStatus.inProgress),
          _task('t3', status: TaskStatus.completed, completedAt: now),
          _task('t4', status: TaskStatus.archived),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.activeCount, 2);
    });

    test('completedTodayCount counts only tasks completed on the current date',
        () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final harness = _Harness()
        ..repo.seed([
          _task('t1', status: TaskStatus.completed, completedAt: now),
          _task('t2', status: TaskStatus.completed, completedAt: now),
          _task('t3', status: TaskStatus.completed, completedAt: yesterday),
          _task('t4', status: TaskStatus.todo),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.completedTodayCount, 2);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });
}
