/// Table and column name constants for the Tasks SQLite schema (DOC-032 §13.2).
///
/// Single source of truth for identifiers referenced by both the schema
/// migration and the repository/DAO layer — mirrors Finance's
/// `FinanceSchema`.
abstract final class TasksSchema {
  static const tasksTable = 'tasks';

  static const taskId = 'task_id';
  static const taskWorkspaceId = 'workspace_id';
  static const taskTitle = 'title';
  static const taskStatus = 'status';
  static const taskDescription = 'description';
  static const taskDueDate = 'due_date';
  static const taskCompletedAt = 'completed_at';
  static const taskCreatedAt = 'created_at';
  static const taskUpdatedAt = 'updated_at';
  static const taskDeletedAt = 'deleted_at';

  // ── Column ordering (DAO insert/update column lists) ─────────────────────

  static const List<String> taskColumns = [
    taskId,
    taskWorkspaceId,
    taskTitle,
    taskStatus,
    taskDescription,
    taskDueDate,
    taskCompletedAt,
    taskCreatedAt,
    taskUpdatedAt,
    taskDeletedAt,
  ];
}
