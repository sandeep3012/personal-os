import 'package:feature_assets/src/data/database/i_asset_database_executor.dart';
import 'package:feature_assets/src/data/models/asset_query_filter.dart';
import 'package:feature_assets/src/data/models/asset_row.dart';
import 'package:feature_assets/src/data/schema/assets_schema.dart';

const _totalCountAlias = 'total';

/// Direct SQL access to the `assets` table.
///
/// Operates exclusively on [AssetRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`), mirroring Notes' `NoteDao`.
final class AssetDao {
  const AssetDao(this._executor);

  final IAssetDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [AssetRow.assetId] — this method performs no existence check.
  Future<void> insert(AssetRow row) async {
    final map = row.toMap();
    const columns = AssetsSchema.assetColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${AssetsSchema.assetsTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by [AssetRow.assetId].
  Future<void> update(AssetRow row) async {
    final map = row.toMap();
    final updatableColumns =
        AssetsSchema.assetColumns.where((c) => c != AssetsSchema.assetId).toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${AssetsSchema.assetsTable} SET $setClause '
      'WHERE ${AssetsSchema.assetId} = ?',
      [...updatableColumns.map((c) => map[c]), row.assetId],
    );
  }

  /// Returns the row with [assetId] within [workspaceId], or `null` if no
  /// matching, non-deleted row exists.
  Future<AssetRow?> findById(
    String assetId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${AssetsSchema.assetsTable} '
      'WHERE ${AssetsSchema.assetId} = ? '
      'AND ${AssetsSchema.assetWorkspaceId} = ? '
      'AND ${AssetsSchema.assetDeletedAt} IS NULL',
      [assetId, workspaceId],
    );
    return rows.isEmpty ? null : AssetRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows within [workspaceId], oldest first.
  Future<List<AssetRow>> findAll(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${AssetsSchema.assetsTable} '
      'WHERE ${AssetsSchema.assetWorkspaceId} = ? '
      'AND ${AssetsSchema.assetDeletedAt} IS NULL '
      'ORDER BY ${AssetsSchema.assetCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(AssetRow.fromMap).toList();
  }

  /// Returns all non-deleted rows within [workspaceId] whose `status`
  /// column equals [status], oldest first.
  Future<List<AssetRow>> findByStatus(
    String status, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${AssetsSchema.assetsTable} '
      'WHERE ${AssetsSchema.assetWorkspaceId} = ? '
      'AND ${AssetsSchema.assetStatus} = ? '
      'AND ${AssetsSchema.assetDeletedAt} IS NULL '
      'ORDER BY ${AssetsSchema.assetCreatedAt} ASC',
      [workspaceId, status],
    );
    return rows.map(AssetRow.fromMap).toList();
  }

  /// Executes [filter] and returns the matching page of rows alongside the
  /// total match count (pre-pagination). Mirrors `NoteDao.query`.
  Future<({List<AssetRow> items, int totalCount})> query(
    AssetQueryFilter filter,
  ) async {
    final where = StringBuffer(
      '${AssetsSchema.assetWorkspaceId} = ? '
      'AND ${AssetsSchema.assetDeletedAt} IS NULL',
    );
    final args = <Object?>[filter.workspaceId];

    if (filter.status != null) {
      where.write(' AND ${AssetsSchema.assetStatus} = ?');
      args.add(filter.status);
    }
    if (filter.nameContains != null && filter.nameContains!.isNotEmpty) {
      where.write(' AND LOWER(${AssetsSchema.assetName}) LIKE ?');
      args.add('%${filter.nameContains!.toLowerCase()}%');
    }
    if (filter.categoryContains != null && filter.categoryContains!.isNotEmpty) {
      where.write(' AND LOWER(${AssetsSchema.assetCategory}) LIKE ?');
      args.add('%${filter.categoryContains!.toLowerCase()}%');
    }

    final countRows = await _executor.query(
      'SELECT COUNT(*) AS $_totalCountAlias '
      'FROM ${AssetsSchema.assetsTable} WHERE $where',
      args,
    );
    final totalCount = countRows.first[_totalCountAlias]! as int;

    final pagedRows = await _executor.query(
      'SELECT * FROM ${AssetsSchema.assetsTable} WHERE $where '
      'ORDER BY ${AssetsSchema.assetCreatedAt} DESC '
      'LIMIT ? OFFSET ?',
      [...args, filter.pageSize, filter.pageIndex * filter.pageSize],
    );

    return (
      items: pagedRows.map(AssetRow.fromMap).toList(),
      totalCount: totalCount,
    );
  }

  /// Sets [AssetsSchema.assetDeletedAt] and [AssetsSchema.assetUpdatedAt] to
  /// [deletedAt]. Idempotent — matches zero rows harmlessly if [assetId]
  /// does not exist or is already soft-deleted.
  Future<void> softDelete(
    String assetId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${AssetsSchema.assetsTable} '
      'SET ${AssetsSchema.assetDeletedAt} = ?, ${AssetsSchema.assetUpdatedAt} = ? '
      'WHERE ${AssetsSchema.assetId} = ? '
      'AND ${AssetsSchema.assetWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        assetId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [assetId] exists within
  /// [workspaceId].
  Future<bool> exists(String assetId, {required String workspaceId}) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${AssetsSchema.assetsTable} '
      'WHERE ${AssetsSchema.assetId} = ? '
      'AND ${AssetsSchema.assetWorkspaceId} = ? '
      'AND ${AssetsSchema.assetDeletedAt} IS NULL '
      'LIMIT 1',
      [assetId, workspaceId],
    );
    return rows.isNotEmpty;
  }
}
