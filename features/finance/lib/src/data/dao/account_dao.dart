import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/models/account_row.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';

/// Direct SQL access to the `accounts` table.
///
/// Operates exclusively on [AccountRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`) per DOC-031 Business Invariant 6.
final class AccountDao {
  const AccountDao(this._executor);

  final IFinanceDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [AccountRow.accountId] — this method performs no existence check.
  Future<void> insert(AccountRow row) async {
    final map = row.toMap();
    const columns = FinanceSchema.accountColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${FinanceSchema.accountsTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by [AccountRow.accountId].
  Future<void> update(AccountRow row) async {
    final map = row.toMap();
    final updatableColumns = FinanceSchema.accountColumns
        .where((c) => c != FinanceSchema.accountId)
        .toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${FinanceSchema.accountsTable} SET $setClause '
      'WHERE ${FinanceSchema.accountId} = ?',
      [...updatableColumns.map((c) => map[c]), row.accountId],
    );
  }

  /// Returns the row with [accountId] within [workspaceId], or `null` if no
  /// matching, non-deleted row exists.
  Future<AccountRow?> findById(
    String accountId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${FinanceSchema.accountsTable} '
      'WHERE ${FinanceSchema.accountId} = ? '
      'AND ${FinanceSchema.accountWorkspaceId} = ? '
      'AND ${FinanceSchema.accountDeletedAt} IS NULL',
      [accountId, workspaceId],
    );
    return rows.isEmpty ? null : AccountRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows within [workspaceId], oldest first.
  Future<List<AccountRow>> findAll(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${FinanceSchema.accountsTable} '
      'WHERE ${FinanceSchema.accountWorkspaceId} = ? '
      'AND ${FinanceSchema.accountDeletedAt} IS NULL '
      'ORDER BY ${FinanceSchema.accountCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(AccountRow.fromMap).toList();
  }

  /// Returns all non-deleted, active (`is_active = 1`) rows within
  /// [workspaceId], oldest first.
  Future<List<AccountRow>> findActive(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${FinanceSchema.accountsTable} '
      'WHERE ${FinanceSchema.accountWorkspaceId} = ? '
      'AND ${FinanceSchema.accountIsActive} = 1 '
      'AND ${FinanceSchema.accountDeletedAt} IS NULL '
      'ORDER BY ${FinanceSchema.accountCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(AccountRow.fromMap).toList();
  }

  /// Sets [FinanceSchema.accountDeletedAt] and
  /// [FinanceSchema.accountUpdatedAt] to [deletedAt]. Idempotent — matches
  /// zero rows harmlessly if [accountId] does not exist or is already
  /// soft-deleted.
  Future<void> softDelete(
    String accountId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${FinanceSchema.accountsTable} '
      'SET ${FinanceSchema.accountDeletedAt} = ?, ${FinanceSchema.accountUpdatedAt} = ? '
      'WHERE ${FinanceSchema.accountId} = ? '
      'AND ${FinanceSchema.accountWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        accountId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [accountId] exists within
  /// [workspaceId].
  Future<bool> exists(String accountId, {required String workspaceId}) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${FinanceSchema.accountsTable} '
      'WHERE ${FinanceSchema.accountId} = ? '
      'AND ${FinanceSchema.accountWorkspaceId} = ? '
      'AND ${FinanceSchema.accountDeletedAt} IS NULL '
      'LIMIT 1',
      [accountId, workspaceId],
    );
    return rows.isNotEmpty;
  }
}
