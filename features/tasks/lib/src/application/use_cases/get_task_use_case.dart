import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetTaskInput {
  const GetTaskInput({required this.taskId, required this.workspaceId});

  final TaskId taskId;
  final String workspaceId;
}

/// Returns a single Task by id. Mirrors `GetAccountByIdUseCase`.
final class GetTaskUseCase implements AsyncUseCase<GetTaskInput, Task> {
  const GetTaskUseCase({required ITaskRepository taskRepository})
      : _taskRepository = taskRepository;

  final ITaskRepository _taskRepository;

  @override
  Future<Result<Task>> execute(GetTaskInput input) async {
    try {
      final result = await _taskRepository.findById(
        input.taskId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final task = result.valueOrNull;
      if (task == null) {
        return Result.failure(
          TasksException(message: 'Task ${input.taskId} not found'),
        );
      }

      return Result.success(task);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
