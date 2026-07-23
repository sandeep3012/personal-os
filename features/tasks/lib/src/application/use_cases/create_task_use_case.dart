import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_due_date.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:platform_core/platform_core.dart';

final class CreateTaskInput {
  const CreateTaskInput({
    required this.workspaceId,
    required this.title,
    this.description,
    this.dueDate,
  });

  final String workspaceId;
  final String title;
  final String? description;
  final TaskDueDate? dueDate;
}

/// Creates a new Task and persists it via [ITaskRepository].
///
/// New tasks always start at [TaskStatus.todo] (DOC-032 §12) — mirrors
/// `CreateAccountUseCase` in shape.
///
/// Validates [CreateTaskInput.description] (max 1000 characters, DOC-032
/// §5.3) at this layer — the [Task] entity constructor enforces the title
/// invariants itself.
final class CreateTaskUseCase implements AsyncUseCase<CreateTaskInput, Task> {
  CreateTaskUseCase({
    required ITaskRepository taskRepository,
    required IdGenerator idGenerator,
  })  : _taskRepository = taskRepository,
        _idGenerator = idGenerator;

  final ITaskRepository _taskRepository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<Task>> execute(CreateTaskInput input) async {
    try {
      if (input.description != null && input.description!.length > 1000) {
        throw const TasksException(
          message: 'Task description must not exceed 1000 characters',
        );
      }

      final now = DateTime.now();
      final task = Task(
        id: TaskId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        title: input.title,
        status: TaskStatus.todo,
        description: input.description,
        dueDate: input.dueDate,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _taskRepository.save(task);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(task);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
