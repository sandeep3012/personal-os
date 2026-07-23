import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_due_date.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateTaskInput {
  const UpdateTaskInput({
    required this.taskId,
    required this.workspaceId,
    this.title,
    this.description,
    this.dueDate,
  });

  final TaskId taskId;
  final String workspaceId;

  /// New title. `null` keeps the existing title.
  final String? title;

  /// New description. `null` keeps the existing description.
  final String? description;

  /// New due date. `null` keeps the existing due date.
  final TaskDueDate? dueDate;
}

/// Updates the mutable, non-status fields of an existing Task.
///
/// `status` is intentionally absent from [UpdateTaskInput] — status changes
/// go through [CompleteTaskUseCase]/[ArchiveTaskUseCase] (DOC-032 §12),
/// mirroring `UpdateAccountUseCase` rejecting currency as an input.
final class UpdateTaskUseCase implements AsyncUseCase<UpdateTaskInput, Task> {
  const UpdateTaskUseCase({required ITaskRepository taskRepository})
      : _taskRepository = taskRepository;

  final ITaskRepository _taskRepository;

  @override
  Future<Result<Task>> execute(UpdateTaskInput input) async {
    try {
      if (input.description != null && input.description!.length > 1000) {
        throw const TasksException(
          message: 'Task description must not exceed 1000 characters',
        );
      }

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

      final updated = existing.copyWith(
        title: input.title,
        description: input.description,
        dueDate: input.dueDate,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _taskRepository.save(updated);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
