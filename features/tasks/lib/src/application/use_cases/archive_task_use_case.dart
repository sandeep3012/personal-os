import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:platform_core/platform_core.dart';

final class ArchiveTaskInput {
  const ArchiveTaskInput({
    required this.taskId,
    required this.workspaceId,
  });

  final TaskId taskId;
  final String workspaceId;
}

/// Transitions a Task to [TaskStatus.archived] from any non-archived status
/// (DOC-032 §11).
///
/// Rejects (via [Task.transitionTo]) if the task is already archived —
/// mirrors Finance's pattern of failing loudly on an invalid precondition
/// rather than silently accepting a no-op.
final class ArchiveTaskUseCase implements AsyncUseCase<ArchiveTaskInput, Task> {
  const ArchiveTaskUseCase({required ITaskRepository taskRepository})
      : _taskRepository = taskRepository;

  final ITaskRepository _taskRepository;

  @override
  Future<Result<Task>> execute(ArchiveTaskInput input) async {
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

      final archived = existing.transitionTo(
        TaskStatus.archived,
        now: DateTime.now(),
      );

      final saveResult = await _taskRepository.save(archived);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(archived);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
