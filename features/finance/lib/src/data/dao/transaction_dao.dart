import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/models/transaction_query_filter.dart';
import 'package:feature_finance/src/data/models/transaction_row.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';

const _totalCountAlias = 'total';

/// Direct SQL access to the `transactions` table.
///
/// Operates exclusively on [TransactionRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`) per DOC-031 Business Invariant 6.
final class TransactionDao {
  const TransactionDao(this._executor);

  final IFinanceDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [TransactionRow.transactionId] — this method performs no existence check.
  Future<void> insert(TransactionRow row) async {
    final map = row.toMap();
    const columns = FinanceSchema.transactionColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${FinanceSchema.transactionsTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by
  /// [TransactionRow.transactionId].
  Future<void> update(TransactionRow row) async {
    final map = row.toMap();
    final updatableColumns = FinanceSchema.transactionColumns
        .where((c) => c != FinanceSchema.transactionId)
        .toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${FinanceSchema.transactionsTable} SET $setClause '
      'WHERE ${FinanceSchema.transactionId} = ?',
      [...updatableColumns.map((c) => map[c]), row.transactionId],
    );
  }

  /// Returns the row with [transactionId] within [workspaceId], or `null` if
  /// no matching, non-deleted row exists.
  Future<TransactionRow?> findById(
    String transactionId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${FinanceSchema.transactionsTable} '
      'WHERE ${FinanceSchema.transactionId} = ? '
      'AND ${FinanceSchema.transactionWorkspaceId} = ? '
      'AND ${FinanceSchema.transactionDeletedAt} IS NULL',
      [transactionId, workspaceId],
    );
    return rows.isEmpty ? null : TransactionRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows for [accountId], optionally restricted to
  /// the inclusive `[start, end]` window, most recent first.
  Future<List<TransactionRow>> findByAccount(
    String accountId, {
    required String workspaceId,
    DateTime? start,
    DateTime? end,
  }) async {
    final where = StringBuffer(
      '${FinanceSchema.transactionAccountId} = ? '
      'AND ${FinanceSchema.transactionWorkspaceId} = ? '
      'AND ${FinanceSchema.transactionDeletedAt} IS NULL',
    );
    final args = <Object?>[accountId, workspaceId];
    _appendDateRange(where, args, start, end);

    final rows = await _executor.query(
      'SELECT * FROM ${FinanceSchema.transactionsTable} WHERE $where '
      'ORDER BY ${FinanceSchema.transactionDate} DESC',
      args,
    );
    return rows.map(TransactionRow.fromMap).toList();
  }

  /// Returns all non-deleted rows across all accounts in [workspaceId] whose
  /// date falls within the inclusive `[start, end]` window, most recent
  /// first.
  Future<List<TransactionRow>> findByPeriod(
    String workspaceId, {
    required DateTime start,
    required DateTime end,
  }) async {
    final where = StringBuffer(
      '${FinanceSchema.transactionWorkspaceId} = ? '
      'AND ${FinanceSchema.transactionDeletedAt} IS NULL',
    );
    final args = <Object?>[workspaceId];
    _appendDateRange(where, args, start, end);

    final rows = await _executor.query(
      'SELECT * FROM ${FinanceSchema.transactionsTable} WHERE $where '
      'ORDER BY ${FinanceSchema.transactionDate} DESC',
      args,
    );
    return rows.map(TransactionRow.fromMap).toList();
  }

  /// Returns all non-deleted rows assigned to [categoryId] within
  /// [workspaceId], optionally restricted to the inclusive `[start, end]`
  /// window, most recent first.
  Future<List<TransactionRow>> findByCategory(
    String categoryId, {
    required String workspaceId,
    DateTime? start,
    DateTime? end,
  }) async {
    final where = StringBuffer(
      '${FinanceSchema.transactionCategoryId} = ? '
      'AND ${FinanceSchema.transactionWorkspaceId} = ? '
      'AND ${FinanceSchema.transactionDeletedAt} IS NULL',
    );
    final args = <Object?>[categoryId, workspaceId];
    _appendDateRange(where, args, start, end);

    final rows = await _executor.query(
      'SELECT * FROM ${FinanceSchema.transactionsTable} WHERE $where '
      'ORDER BY ${FinanceSchema.transactionDate} DESC',
      args,
    );
    return rows.map(TransactionRow.fromMap).toList();
  }

  /// Executes [filter] and returns the matching page of rows alongside the
  /// total match count (pre-pagination).
  Future<({List<TransactionRow> items, int totalCount})> query(
    TransactionQueryFilter filter,
  ) async {
    final where = StringBuffer(
      '${FinanceSchema.transactionWorkspaceId} = ? '
      'AND ${FinanceSchema.transactionDeletedAt} IS NULL',
    );
    final args = <Object?>[filter.workspaceId];

    if (filter.accountId != null) {
      where.write(' AND ${FinanceSchema.transactionAccountId} = ?');
      args.add(filter.accountId);
    }
    if (filter.categoryId != null) {
      where.write(' AND ${FinanceSchema.transactionCategoryId} = ?');
      args.add(filter.categoryId);
    }
    if (filter.transactionType != null) {
      where.write(' AND ${FinanceSchema.transactionType} = ?');
      args.add(filter.transactionType);
    }
    _appendDateRange(where, args, filter.startDate, filter.endDate);
    if (filter.payeeContains != null && filter.payeeContains!.isNotEmpty) {
      where.write(' AND LOWER(${FinanceSchema.transactionPayee}) LIKE ?');
      args.add('%${filter.payeeContains!.toLowerCase()}%');
    }

    final countRows = await _executor.query(
      'SELECT COUNT(*) AS $_totalCountAlias '
      'FROM ${FinanceSchema.transactionsTable} WHERE $where',
      args,
    );
    final totalCount = countRows.first[_totalCountAlias]! as int;

    final pagedRows = await _executor.query(
      'SELECT * FROM ${FinanceSchema.transactionsTable} WHERE $where '
      'ORDER BY ${FinanceSchema.transactionDate} DESC '
      'LIMIT ? OFFSET ?',
      [...args, filter.pageSize, filter.pageIndex * filter.pageSize],
    );

    return (
      items: pagedRows.map(TransactionRow.fromMap).toList(),
      totalCount: totalCount,
    );
  }

  /// Returns the non-deleted counterpart row of [transactionId] — the row
  /// whose `transaction_id` equals [transactionId]'s `transfer_pair_id` —
  /// or `null` if [transactionId] is not part of a transfer, does not exist,
  /// or its counterpart is not found.
  Future<TransactionRow?> findTransferPair(
    String transactionId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT t2.* FROM ${FinanceSchema.transactionsTable} t1 '
      'JOIN ${FinanceSchema.transactionsTable} t2 '
      'ON t2.${FinanceSchema.transactionId} = t1.${FinanceSchema.transactionTransferPairId} '
      'WHERE t1.${FinanceSchema.transactionId} = ? '
      'AND t1.${FinanceSchema.transactionWorkspaceId} = ? '
      'AND t2.${FinanceSchema.transactionDeletedAt} IS NULL',
      [transactionId, workspaceId],
    );
    return rows.isEmpty ? null : TransactionRow.fromMap(rows.first);
  }

  /// Sets [FinanceSchema.transactionDeletedAt] and
  /// [FinanceSchema.transactionUpdatedAt] to [deletedAt]. Idempotent —
  /// matches zero rows harmlessly if [transactionId] does not exist or is
  /// already soft-deleted.
  Future<void> softDelete(
    String transactionId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${FinanceSchema.transactionsTable} '
      'SET ${FinanceSchema.transactionDeletedAt} = ?, ${FinanceSchema.transactionUpdatedAt} = ? '
      'WHERE ${FinanceSchema.transactionId} = ? '
      'AND ${FinanceSchema.transactionWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        transactionId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [transactionId] exists within
  /// [workspaceId].
  Future<bool> exists(
    String transactionId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${FinanceSchema.transactionsTable} '
      'WHERE ${FinanceSchema.transactionId} = ? '
      'AND ${FinanceSchema.transactionWorkspaceId} = ? '
      'AND ${FinanceSchema.transactionDeletedAt} IS NULL '
      'LIMIT 1',
      [transactionId, workspaceId],
    );
    return rows.isNotEmpty;
  }

  void _appendDateRange(
    StringBuffer where,
    List<Object?> args,
    DateTime? start,
    DateTime? end,
  ) {
    if (start != null) {
      where.write(' AND ${FinanceSchema.transactionDate} >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.write(' AND ${FinanceSchema.transactionDate} <= ?');
      args.add(end.toIso8601String());
    }
  }
}
