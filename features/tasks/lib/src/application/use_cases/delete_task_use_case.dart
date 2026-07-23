import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteTaskInput {
  const DeleteTaskInput({
    required this.taskId,
    required this.workspaceId,
  });

  final TaskId taskId;
  final String workspaceId;
}

/// Soft-deletes a Task (DOC-032 §10 Business Rule 6).
///
/// No precondition beyond existence — unlike Finance's
/// `DeleteAccountUseCase` (which checks for active transactions before
/// allowing deletion), nothing about a Task's own fields creates a
/// cross-entity precondition (DOC-032 §4/§8: Task is a standalone aggregate,
/// no domain services needed).
final class DeleteTaskUseCase implements AsyncUseCase<DeleteTaskInput, void> {
  const DeleteTaskUseCase({required ITaskRepository taskRepository})
      : _taskRepository = taskRepository;

  final ITaskRepository _taskRepository;

  @override
  Future<Result<void>> execute(DeleteTaskInput input) async {
    try {
      final deleteResult = await _taskRepository.softDelete(
        input.taskId,
        workspaceId: input.workspaceId,
      );
      if (deleteResult.isFailure) {
        return Result.failure(deleteResult.exceptionOrNull!);
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
