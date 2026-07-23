import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetTasksInput {
  const GetTasksInput({required this.workspaceId});

  final String workspaceId;
}

/// Returns all non-deleted tasks in the workspace, regardless of status
/// (DOC-032 §12) — filtering by status is [SearchTasksUseCase]'s job.
/// Mirrors `GetAccountsUseCase` in shape (though `GetAccountsUseCase`
/// additionally filters to active accounts — Task has no equivalent
/// `isActive` flag to filter by; `archived` is a status value, not a hidden
/// flag, so it is not excluded here).
final class GetTasksUseCase implements AsyncUseCase<GetTasksInput, List<Task>> {
  const GetTasksUseCase({required ITaskRepository taskRepository})
      : _taskRepository = taskRepository;

  final ITaskRepository _taskRepository;

  @override
  Future<Result<List<Task>>> execute(GetTasksInput input) async {
    try {
      final result =
          await _taskRepository.findAll(workspaceId: input.workspaceId);
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return Result.success(result.valueOrNull!);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
