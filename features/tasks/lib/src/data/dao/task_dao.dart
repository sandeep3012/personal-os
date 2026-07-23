import 'package:feature_tasks/src/data/database/i_task_database_executor.dart';
import 'package:feature_tasks/src/data/models/task_query_filter.dart';
import 'package:feature_tasks/src/data/models/task_row.dart';
import 'package:feature_tasks/src/data/schema/tasks_schema.dart';

const _totalCountAlias = 'total';

/// Direct SQL access to the `tasks` table.
///
/// Operates exclusively on [TaskRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`), mirroring Finance's `AccountDao`/`TransactionDao`.
final class TaskDao {
  const TaskDao(this._executor);

  final ITaskDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [TaskRow.taskId] — this method performs no existence check.
  Future<void> insert(TaskRow row) async {
    final map = row.toMap();
    const columns = TasksSchema.taskColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${TasksSchema.tasksTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by [TaskRow.taskId].
  Future<void> update(TaskRow row) async {
    final map = row.toMap();
    final updatableColumns =
        TasksSchema.taskColumns.where((c) => c != TasksSchema.taskId).toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${TasksSchema.tasksTable} SET $setClause '
      'WHERE ${TasksSchema.taskId} = ?',
      [...updatableColumns.map((c) => map[c]), row.taskId],
    );
  }

  /// Returns the row with [taskId] within [workspaceId], or `null` if no
  /// matching, non-deleted row exists.
  Future<TaskRow?> findById(
    String taskId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${TasksSchema.tasksTable} '
      'WHERE ${TasksSchema.taskId} = ? '
      'AND ${TasksSchema.taskWorkspaceId} = ? '
      'AND ${TasksSchema.taskDeletedAt} IS NULL',
      [taskId, workspaceId],
    );
    return rows.isEmpty ? null : TaskRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows within [workspaceId], oldest first.
  Future<List<TaskRow>> findAll(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${TasksSchema.tasksTable} '
      'WHERE ${TasksSchema.taskWorkspaceId} = ? '
      'AND ${TasksSchema.taskDeletedAt} IS NULL '
      'ORDER BY ${TasksSchema.taskCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(TaskRow.fromMap).toList();
  }

  /// Returns all non-deleted rows within [workspaceId] whose `status` column
  /// equals [status], oldest first.
  Future<List<TaskRow>> findByStatus(
    String status, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${TasksSchema.tasksTable} '
      'WHERE ${TasksSchema.taskWorkspaceId} = ? '
      'AND ${TasksSchema.taskStatus} = ? '
      'AND ${TasksSchema.taskDeletedAt} IS NULL '
      'ORDER BY ${TasksSchema.taskCreatedAt} ASC',
      [workspaceId, status],
    );
    return rows.map(TaskRow.fromMap).toList();
  }

  /// Executes [filter] and returns the matching page of rows alongside the
  /// total match count (pre-pagination). Mirrors `TransactionDao.query`.
  Future<({List<TaskRow> items, int totalCount})> query(
    TaskQueryFilter filter,
  ) async {
    final where = StringBuffer(
      '${TasksSchema.taskWorkspaceId} = ? '
      'AND ${TasksSchema.taskDeletedAt} IS NULL',
    );
    final args = <Object?>[filter.workspaceId];

    if (filter.status != null) {
      where.write(' AND ${TasksSchema.taskStatus} = ?');
      args.add(filter.status);
    }
    if (filter.titleContains != null && filter.titleContains!.isNotEmpty) {
      where.write(' AND LOWER(${TasksSchema.taskTitle}) LIKE ?');
      args.add('%${filter.titleContains!.toLowerCase()}%');
    }

    final countRows = await _executor.query(
      'SELECT COUNT(*) AS $_totalCountAlias '
      'FROM ${TasksSchema.tasksTable} WHERE $where',
      args,
    );
    final totalCount = countRows.first[_totalCountAlias]! as int;

    final pagedRows = await _executor.query(
      'SELECT * FROM ${TasksSchema.tasksTable} WHERE $where '
      'ORDER BY ${TasksSchema.taskCreatedAt} DESC '
      'LIMIT ? OFFSET ?',
      [...args, filter.pageSize, filter.pageIndex * filter.pageSize],
    );

    return (
      items: pagedRows.map(TaskRow.fromMap).toList(),
      totalCount: totalCount,
    );
  }

  /// Sets [TasksSchema.taskDeletedAt] and [TasksSchema.taskUpdatedAt] to
  /// [deletedAt]. Idempotent — matches zero rows harmlessly if [taskId] does
  /// not exist or is already soft-deleted.
  Future<void> softDelete(
    String taskId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${TasksSchema.tasksTable} '
      'SET ${TasksSchema.taskDeletedAt} = ?, ${TasksSchema.taskUpdatedAt} = ? '
      'WHERE ${TasksSchema.taskId} = ? '
      'AND ${TasksSchema.taskWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        taskId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [taskId] exists within
  /// [workspaceId].
  Future<bool> exists(String taskId, {required String workspaceId}) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${TasksSchema.tasksTable} '
      'WHERE ${TasksSchema.taskId} = ? '
      'AND ${TasksSchema.taskWorkspaceId} = ? '
      'AND ${TasksSchema.taskDeletedAt} IS NULL '
      'LIMIT 1',
      [taskId, workspaceId],
    );
    return rows.isNotEmpty;
  }
}
