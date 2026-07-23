import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:platform_core/platform_core.dart';

final class CompleteTaskInput {
  const CompleteTaskInput({
    required this.taskId,
    required this.workspaceId,
  });

  final TaskId taskId;
  final String workspaceId;
}

/// Transitions a Task to [TaskStatus.completed], setting `completedAt`
/// (DOC-032 §10 Business Rule 4).
///
/// Orchestration only — the transition-legality check (rejecting the
/// transition if the task is already [TaskStatus.archived], per the
/// approved transition table, DOC-032 §11) lives on [Task.transitionTo],
/// not here.
final class CompleteTaskUseCase
    implements AsyncUseCase<CompleteTaskInput, Task> {
  const CompleteTaskUseCase({required ITaskRepository taskRepository})
      : _taskRepository = taskRepository;

  final ITaskRepository _taskRepository;

  @override
  Future<Result<Task>> execute(CompleteTaskInput input) async {
    try {
      final findResult = await _taskRepository.findById(
        input.taskId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) return Result.failure(findResult.exceptionOrNull!);

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(
          TasksException(message: 'Task ${input.taskId} not found'),
        );
      }

      final completed = existing.transitionTo(
        TaskStatus.completed,
        now: DateTime.now(),
      );

      final saveResult = await _taskRepository.save(completed);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(completed);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
