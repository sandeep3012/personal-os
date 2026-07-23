import 'package:feature_tasks/src/data/schema/tasks_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `tasks` table (DOC-032 §13.2) and its supporting indexes.
///
/// [Task.status] is a `TEXT` column constrained to the values of the actual
/// `TaskStatus` enum (`todo`, `inProgress`, `completed`, `archived` — see
/// `task_status.dart`). Mirrors Finance's `CreateAccountsTableMigration`
/// exactly, including its current status: declared for parity and as
/// schema-as-code documentation, not yet wired into a runtime migration
/// runner, since the active executor is the hand-rolled in-memory/file-backed
/// engine rather than a real SQL engine (same as Finance today).
///
/// Soft delete is represented by nullable [TasksSchema.taskDeletedAt] rather
/// than a boolean flag, so the deletion moment is recoverable for
/// audit/debugging — the [Task] entity itself has no such field; this is
/// purely a storage-layer concern.
final class CreateTasksTableMigration extends Migration {
  const CreateTasksTableMigration() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${TasksSchema.tasksTable} (
        ${TasksSchema.taskId}            TEXT    PRIMARY KEY,
        ${TasksSchema.taskWorkspaceId}    TEXT    NOT NULL,
        ${TasksSchema.taskTitle}          TEXT    NOT NULL CHECK (length(trim(${TasksSchema.taskTitle})) > 0),
        ${TasksSchema.taskStatus}         TEXT    NOT NULL CHECK (${TasksSchema.taskStatus} IN ('todo', 'inProgress', 'completed', 'archived')),
        ${TasksSchema.taskDescription}    TEXT,
        ${TasksSchema.taskDueDate}        TEXT,
        ${TasksSchema.taskCompletedAt}    TEXT,
        ${TasksSchema.taskCreatedAt}      TEXT    NOT NULL,
        ${TasksSchema.taskUpdatedAt}      TEXT    NOT NULL,
        ${TasksSchema.taskDeletedAt}      TEXT
      )
    ''');

    // Serves ITaskRepository.findAll(workspaceId) and general workspace scoping.
    await ctx.execute('''
      CREATE INDEX idx_tasks_workspace_id
      ON ${TasksSchema.tasksTable} (${TasksSchema.taskWorkspaceId})
    ''');

    // Serves ITaskRepository.findByStatus(workspaceId, status); excludes
    // soft-deleted rows.
    await ctx.execute('''
      CREATE INDEX idx_tasks_workspace_status
      ON ${TasksSchema.tasksTable} (${TasksSchema.taskWorkspaceId}, ${TasksSchema.taskStatus})
      WHERE ${TasksSchema.taskDeletedAt} IS NULL
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_tasks_workspace_status');
    await ctx.execute('DROP INDEX IF EXISTS idx_tasks_workspace_id');
    await ctx.execute('DROP TABLE IF EXISTS ${TasksSchema.tasksTable}');
  }
}
