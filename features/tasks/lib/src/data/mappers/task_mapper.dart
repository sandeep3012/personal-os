import 'package:feature_tasks/src/data/models/task_row.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_due_date.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';

/// Converts between the domain [Task] entity and the persistence [TaskRow]
/// model. Pure conversion only — no validation, no repository calls, no SQL,
/// no business rules. Mirrors Finance's `AccountMapper`/`TransactionMapper`.
///
/// [Task] never represents a soft-deleted row: [TaskDao]'s read methods
/// already exclude soft-deleted rows (`deleted_at IS NULL`), so a domain
/// [Task] instance can never have been loaded from a deleted row in the
/// first place. Consequently [toRow] always sets [TaskRow.deletedAt] to
/// `null`.
final class TaskMapper {
  const TaskMapper();

  /// Converts a persisted [TaskRow] to a domain [Task].
  ///
  /// Throws [TasksException] if [TaskRow.status] does not correspond to a
  /// value this mapper recognizes — corrupted or unsupported persisted data
  /// must fail loudly rather than be silently coerced.
  Task toEntity(TaskRow row) {
    return Task(
      id: TaskId(row.taskId),
      workspaceId: row.workspaceId,
      title: row.title,
      status: _statusFromColumnValue(row.status),
      description: row.description,
      dueDate: row.dueDate == null ? null : TaskDueDate(row.dueDate!),
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Task] to a persistable [TaskRow].
  TaskRow toRow(Task task) {
    return TaskRow(
      taskId: task.id.value,
      workspaceId: task.workspaceId,
      title: task.title,
      status: task.status.name,
      description: task.description,
      dueDate: task.dueDate?.value,
      completedAt: task.completedAt,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      deletedAt: null,
    );
  }

  TaskStatus _statusFromColumnValue(String value) {
    for (final status in TaskStatus.values) {
      if (status.name == value) return status;
    }
    throw TasksException(
      message: 'Unrecognized status value persisted: "$value"',
    );
  }
}
