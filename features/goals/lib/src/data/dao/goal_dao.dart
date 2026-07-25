import 'package:feature_goals/src/data/database/i_goal_database_executor.dart';
import 'package:feature_goals/src/data/models/goal_query_filter.dart';
import 'package:feature_goals/src/data/models/goal_row.dart';
import 'package:feature_goals/src/data/schema/goals_schema.dart';

const _totalCountAlias = 'total';

/// Direct SQL access to the `goals` table.
///
/// Operates exclusively on [GoalRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`), mirroring Finance's `AccountDao`/`TransactionDao`.
final class GoalDao {
  const GoalDao(this._executor);

  final IGoalDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [GoalRow.goalId] — this method performs no existence check.
  Future<void> insert(GoalRow row) async {
    final map = row.toMap();
    const columns = GoalsSchema.goalColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${GoalsSchema.goalsTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by [GoalRow.goalId].
  Future<void> update(GoalRow row) async {
    final map = row.toMap();
    final updatableColumns =
        GoalsSchema.goalColumns.where((c) => c != GoalsSchema.goalId).toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${GoalsSchema.goalsTable} SET $setClause '
      'WHERE ${GoalsSchema.goalId} = ?',
      [...updatableColumns.map((c) => map[c]), row.goalId],
    );
  }

  /// Returns the row with [goalId] within [workspaceId], or `null` if no
  /// matching, non-deleted row exists.
  Future<GoalRow?> findById(
    String goalId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${GoalsSchema.goalsTable} '
      'WHERE ${GoalsSchema.goalId} = ? '
      'AND ${GoalsSchema.goalWorkspaceId} = ? '
      'AND ${GoalsSchema.goalDeletedAt} IS NULL',
      [goalId, workspaceId],
    );
    return rows.isEmpty ? null : GoalRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows within [workspaceId], oldest first.
  Future<List<GoalRow>> findAll(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${GoalsSchema.goalsTable} '
      'WHERE ${GoalsSchema.goalWorkspaceId} = ? '
      'AND ${GoalsSchema.goalDeletedAt} IS NULL '
      'ORDER BY ${GoalsSchema.goalCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(GoalRow.fromMap).toList();
  }

  /// Returns all non-deleted rows within [workspaceId] whose `status` column
  /// equals [status], oldest first.
  Future<List<GoalRow>> findByStatus(
    String status, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${GoalsSchema.goalsTable} '
      'WHERE ${GoalsSchema.goalWorkspaceId} = ? '
      'AND ${GoalsSchema.goalStatus} = ? '
      'AND ${GoalsSchema.goalDeletedAt} IS NULL '
      'ORDER BY ${GoalsSchema.goalCreatedAt} ASC',
      [workspaceId, status],
    );
    return rows.map(GoalRow.fromMap).toList();
  }

  /// Executes [filter] and returns the matching page of rows alongside the
  /// total match count (pre-pagination). Mirrors `TransactionDao.query`.
  Future<({List<GoalRow> items, int totalCount})> query(
    GoalQueryFilter filter,
  ) async {
    final where = StringBuffer(
      '${GoalsSchema.goalWorkspaceId} = ? '
      'AND ${GoalsSchema.goalDeletedAt} IS NULL',
    );
    final args = <Object?>[filter.workspaceId];

    if (filter.status != null) {
      where.write(' AND ${GoalsSchema.goalStatus} = ?');
      args.add(filter.status);
    }
    if (filter.nameContains != null && filter.nameContains!.isNotEmpty) {
      where.write(' AND LOWER(${GoalsSchema.goalName}) LIKE ?');
      args.add('%${filter.nameContains!.toLowerCase()}%');
    }

    final countRows = await _executor.query(
      'SELECT COUNT(*) AS $_totalCountAlias '
      'FROM ${GoalsSchema.goalsTable} WHERE $where',
      args,
    );
    final totalCount = countRows.first[_totalCountAlias]! as int;

    final pagedRows = await _executor.query(
      'SELECT * FROM ${GoalsSchema.goalsTable} WHERE $where '
      'ORDER BY ${GoalsSchema.goalCreatedAt} DESC '
      'LIMIT ? OFFSET ?',
      [...args, filter.pageSize, filter.pageIndex * filter.pageSize],
    );

    return (
      items: pagedRows.map(GoalRow.fromMap).toList(),
      totalCount: totalCount,
    );
  }

  /// Sets [GoalsSchema.goalDeletedAt] and [GoalsSchema.goalUpdatedAt] to
  /// [deletedAt]. Idempotent — matches zero rows harmlessly if [goalId] does
  /// not exist or is already soft-deleted.
  Future<void> softDelete(
    String goalId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${GoalsSchema.goalsTable} '
      'SET ${GoalsSchema.goalDeletedAt} = ?, ${GoalsSchema.goalUpdatedAt} = ? '
      'WHERE ${GoalsSchema.goalId} = ? '
      'AND ${GoalsSchema.goalWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        goalId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [goalId] exists within
  /// [workspaceId].
  Future<bool> exists(String goalId, {required String workspaceId}) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${GoalsSchema.goalsTable} '
      'WHERE ${GoalsSchema.goalId} = ? '
      'AND ${GoalsSchema.goalWorkspaceId} = ? '
      'AND ${GoalsSchema.goalDeletedAt} IS NULL '
      'LIMIT 1',
      [goalId, workspaceId],
    );
    return rows.isNotEmpty;
  }
}
