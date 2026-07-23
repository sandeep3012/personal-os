import 'package:feature_tasks/src/data/schema/tasks_schema.dart';

/// A single, unmapped row from the `tasks` table.
///
/// [TaskRow] is a persistence-layer data shape only — it has no business
/// methods, no validation, and no relationship to the domain `Task` entity.
/// Mapping between [TaskRow] and `Task` is a repository-layer concern, not a
/// DAO concern. Mirrors Finance's `AccountRow`/`TransactionRow`.
final class TaskRow {
  const TaskRow({
    required this.taskId,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.dueDate,
    this.completedAt,
    this.deletedAt,
  });

  final String taskId;
  final String workspaceId;
  final String title;
  final String status;
  final String? description;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Builds a [TaskRow] from a raw SQL result row.
  factory TaskRow.fromMap(Map<String, Object?> map) {
    final dueDateValue = map[TasksSchema.taskDueDate] as String?;
    final completedAtValue = map[TasksSchema.taskCompletedAt] as String?;
    final deletedAtValue = map[TasksSchema.taskDeletedAt] as String?;
    return TaskRow(
      taskId: map[TasksSchema.taskId]! as String,
      workspaceId: map[TasksSchema.taskWorkspaceId]! as String,
      title: map[TasksSchema.taskTitle]! as String,
      status: map[TasksSchema.taskStatus]! as String,
      description: map[TasksSchema.taskDescription] as String?,
      dueDate: dueDateValue == null ? null : DateTime.parse(dueDateValue),
      completedAt:
          completedAtValue == null ? null : DateTime.parse(completedAtValue),
      createdAt: DateTime.parse(map[TasksSchema.taskCreatedAt]! as String),
      updatedAt: DateTime.parse(map[TasksSchema.taskUpdatedAt]! as String),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [TasksSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        TasksSchema.taskId: taskId,
        TasksSchema.taskWorkspaceId: workspaceId,
        TasksSchema.taskTitle: title,
        TasksSchema.taskStatus: status,
        TasksSchema.taskDescription: description,
        TasksSchema.taskDueDate: dueDate?.toIso8601String(),
        TasksSchema.taskCompletedAt: completedAt?.toIso8601String(),
        TasksSchema.taskCreatedAt: createdAt.toIso8601String(),
        TasksSchema.taskUpdatedAt: updatedAt.toIso8601String(),
        TasksSchema.taskDeletedAt: deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.taskId == taskId &&
          other.workspaceId == workspaceId &&
          other.title == title &&
          other.status == status &&
          other.description == description &&
          other.dueDate == dueDate &&
          other.completedAt == completedAt &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        taskId,
        workspaceId,
        title,
        status,
        description,
        dueDate,
        completedAt,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'TaskRow(taskId: $taskId, title: $title)';
}
