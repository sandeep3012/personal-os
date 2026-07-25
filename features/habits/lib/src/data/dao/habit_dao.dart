import 'package:feature_habits/src/data/database/i_habit_database_executor.dart';
import 'package:feature_habits/src/data/models/habit_query_filter.dart';
import 'package:feature_habits/src/data/models/habit_row.dart';
import 'package:feature_habits/src/data/schema/habits_schema.dart';

const _totalCountAlias = 'total';

/// Direct SQL access to the `habits` table.
///
/// Operates exclusively on [HabitRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`), mirroring Finance's `AccountDao`/`TransactionDao`.
final class HabitDao {
  const HabitDao(this._executor);

  final IHabitDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [HabitRow.habitId] — this method performs no existence check.
  Future<void> insert(HabitRow row) async {
    final map = row.toMap();
    const columns = HabitsSchema.habitColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${HabitsSchema.habitsTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by [HabitRow.habitId].
  Future<void> update(HabitRow row) async {
    final map = row.toMap();
    final updatableColumns =
        HabitsSchema.habitColumns.where((c) => c != HabitsSchema.habitId).toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${HabitsSchema.habitsTable} SET $setClause '
      'WHERE ${HabitsSchema.habitId} = ?',
      [...updatableColumns.map((c) => map[c]), row.habitId],
    );
  }

  /// Returns the row with [habitId] within [workspaceId], or `null` if no
  /// matching, non-deleted row exists.
  Future<HabitRow?> findById(
    String habitId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${HabitsSchema.habitsTable} '
      'WHERE ${HabitsSchema.habitId} = ? '
      'AND ${HabitsSchema.habitWorkspaceId} = ? '
      'AND ${HabitsSchema.habitDeletedAt} IS NULL',
      [habitId, workspaceId],
    );
    return rows.isEmpty ? null : HabitRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows within [workspaceId], oldest first.
  Future<List<HabitRow>> findAll(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${HabitsSchema.habitsTable} '
      'WHERE ${HabitsSchema.habitWorkspaceId} = ? '
      'AND ${HabitsSchema.habitDeletedAt} IS NULL '
      'ORDER BY ${HabitsSchema.habitCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(HabitRow.fromMap).toList();
  }

  /// Returns all non-deleted rows within [workspaceId] whose `status` column
  /// equals [status], oldest first.
  Future<List<HabitRow>> findByStatus(
    String status, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${HabitsSchema.habitsTable} '
      'WHERE ${HabitsSchema.habitWorkspaceId} = ? '
      'AND ${HabitsSchema.habitStatus} = ? '
      'AND ${HabitsSchema.habitDeletedAt} IS NULL '
      'ORDER BY ${HabitsSchema.habitCreatedAt} ASC',
      [workspaceId, status],
    );
    return rows.map(HabitRow.fromMap).toList();
  }

  /// Executes [filter] and returns the matching page of rows alongside the
  /// total match count (pre-pagination). Mirrors `TransactionDao.query`.
  Future<({List<HabitRow> items, int totalCount})> query(
    HabitQueryFilter filter,
  ) async {
    final where = StringBuffer(
      '${HabitsSchema.habitWorkspaceId} = ? '
      'AND ${HabitsSchema.habitDeletedAt} IS NULL',
    );
    final args = <Object?>[filter.workspaceId];

    if (filter.status != null) {
      where.write(' AND ${HabitsSchema.habitStatus} = ?');
      args.add(filter.status);
    }
    if (filter.nameContains != null && filter.nameContains!.isNotEmpty) {
      where.write(' AND LOWER(${HabitsSchema.habitName}) LIKE ?');
      args.add('%${filter.nameContains!.toLowerCase()}%');
    }

    final countRows = await _executor.query(
      'SELECT COUNT(*) AS $_totalCountAlias '
      'FROM ${HabitsSchema.habitsTable} WHERE $where',
      args,
    );
    final totalCount = countRows.first[_totalCountAlias]! as int;

    final pagedRows = await _executor.query(
      'SELECT * FROM ${HabitsSchema.habitsTable} WHERE $where '
      'ORDER BY ${HabitsSchema.habitCreatedAt} DESC '
      'LIMIT ? OFFSET ?',
      [...args, filter.pageSize, filter.pageIndex * filter.pageSize],
    );

    return (
      items: pagedRows.map(HabitRow.fromMap).toList(),
      totalCount: totalCount,
    );
  }

  /// Sets [HabitsSchema.habitDeletedAt] and [HabitsSchema.habitUpdatedAt] to
  /// [deletedAt]. Idempotent — matches zero rows harmlessly if [habitId] does
  /// not exist or is already soft-deleted.
  Future<void> softDelete(
    String habitId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${HabitsSchema.habitsTable} '
      'SET ${HabitsSchema.habitDeletedAt} = ?, ${HabitsSchema.habitUpdatedAt} = ? '
      'WHERE ${HabitsSchema.habitId} = ? '
      'AND ${HabitsSchema.habitWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        habitId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [habitId] exists within
  /// [workspaceId].
  Future<bool> exists(String habitId, {required String workspaceId}) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${HabitsSchema.habitsTable} '
      'WHERE ${HabitsSchema.habitId} = ? '
      'AND ${HabitsSchema.habitWorkspaceId} = ? '
      'AND ${HabitsSchema.habitDeletedAt} IS NULL '
      'LIMIT 1',
      [habitId, workspaceId],
    );
    return rows.isNotEmpty;
  }
}
