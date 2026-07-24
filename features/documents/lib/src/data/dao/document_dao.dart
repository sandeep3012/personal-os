import 'package:feature_documents/src/data/database/i_document_database_executor.dart';
import 'package:feature_documents/src/data/models/document_query_filter.dart';
import 'package:feature_documents/src/data/models/document_row.dart';
import 'package:feature_documents/src/data/schema/documents_schema.dart';

const _totalCountAlias = 'total';

/// Direct SQL access to the `documents` table.
///
/// Operates exclusively on [DocumentRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`), mirroring Notes' `NoteDao`.
final class DocumentDao {
  const DocumentDao(this._executor);

  final IDocumentDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [DocumentRow.documentId] — this method performs no existence check.
  Future<void> insert(DocumentRow row) async {
    final map = row.toMap();
    const columns = DocumentsSchema.documentColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${DocumentsSchema.documentsTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by [DocumentRow.documentId].
  Future<void> update(DocumentRow row) async {
    final map = row.toMap();
    final updatableColumns =
        DocumentsSchema.documentColumns.where((c) => c != DocumentsSchema.documentId).toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${DocumentsSchema.documentsTable} SET $setClause '
      'WHERE ${DocumentsSchema.documentId} = ?',
      [...updatableColumns.map((c) => map[c]), row.documentId],
    );
  }

  /// Returns the row with [documentId] within [workspaceId], or `null` if no
  /// matching, non-deleted row exists.
  Future<DocumentRow?> findById(
    String documentId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${DocumentsSchema.documentsTable} '
      'WHERE ${DocumentsSchema.documentId} = ? '
      'AND ${DocumentsSchema.documentWorkspaceId} = ? '
      'AND ${DocumentsSchema.documentDeletedAt} IS NULL',
      [documentId, workspaceId],
    );
    return rows.isEmpty ? null : DocumentRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows within [workspaceId], oldest first.
  Future<List<DocumentRow>> findAll(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${DocumentsSchema.documentsTable} '
      'WHERE ${DocumentsSchema.documentWorkspaceId} = ? '
      'AND ${DocumentsSchema.documentDeletedAt} IS NULL '
      'ORDER BY ${DocumentsSchema.documentCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(DocumentRow.fromMap).toList();
  }

  /// Returns all non-deleted rows within [workspaceId] whose `status`
  /// column equals [status], oldest first.
  Future<List<DocumentRow>> findByStatus(
    String status, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${DocumentsSchema.documentsTable} '
      'WHERE ${DocumentsSchema.documentWorkspaceId} = ? '
      'AND ${DocumentsSchema.documentStatus} = ? '
      'AND ${DocumentsSchema.documentDeletedAt} IS NULL '
      'ORDER BY ${DocumentsSchema.documentCreatedAt} ASC',
      [workspaceId, status],
    );
    return rows.map(DocumentRow.fromMap).toList();
  }

  /// Executes [filter] and returns the matching page of rows alongside the
  /// total match count (pre-pagination). Mirrors `NoteDao.query`.
  Future<({List<DocumentRow> items, int totalCount})> query(
    DocumentQueryFilter filter,
  ) async {
    final where = StringBuffer(
      '${DocumentsSchema.documentWorkspaceId} = ? '
      'AND ${DocumentsSchema.documentDeletedAt} IS NULL',
    );
    final args = <Object?>[filter.workspaceId];

    if (filter.status != null) {
      where.write(' AND ${DocumentsSchema.documentStatus} = ?');
      args.add(filter.status);
    }
    if (filter.titleContains != null && filter.titleContains!.isNotEmpty) {
      where.write(' AND LOWER(${DocumentsSchema.documentTitle}) LIKE ?');
      args.add('%${filter.titleContains!.toLowerCase()}%');
    }
    if (filter.typeContains != null && filter.typeContains!.isNotEmpty) {
      where.write(' AND LOWER(${DocumentsSchema.documentType}) LIKE ?');
      args.add('%${filter.typeContains!.toLowerCase()}%');
    }
    if (filter.tagContains != null && filter.tagContains!.isNotEmpty) {
      where.write(' AND LOWER(${DocumentsSchema.documentTags}) LIKE ?');
      args.add('%${filter.tagContains!.toLowerCase()}%');
    }

    final countRows = await _executor.query(
      'SELECT COUNT(*) AS $_totalCountAlias '
      'FROM ${DocumentsSchema.documentsTable} WHERE $where',
      args,
    );
    final totalCount = countRows.first[_totalCountAlias]! as int;

    final pagedRows = await _executor.query(
      'SELECT * FROM ${DocumentsSchema.documentsTable} WHERE $where '
      'ORDER BY ${DocumentsSchema.documentCreatedAt} DESC '
      'LIMIT ? OFFSET ?',
      [...args, filter.pageSize, filter.pageIndex * filter.pageSize],
    );

    return (
      items: pagedRows.map(DocumentRow.fromMap).toList(),
      totalCount: totalCount,
    );
  }

  /// Sets [DocumentsSchema.documentDeletedAt] and [DocumentsSchema.documentUpdatedAt] to
  /// [deletedAt]. Idempotent — matches zero rows harmlessly if [documentId]
  /// does not exist or is already soft-deleted.
  Future<void> softDelete(
    String documentId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${DocumentsSchema.documentsTable} '
      'SET ${DocumentsSchema.documentDeletedAt} = ?, ${DocumentsSchema.documentUpdatedAt} = ? '
      'WHERE ${DocumentsSchema.documentId} = ? '
      'AND ${DocumentsSchema.documentWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        documentId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [documentId] exists within
  /// [workspaceId].
  Future<bool> exists(String documentId, {required String workspaceId}) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${DocumentsSchema.documentsTable} '
      'WHERE ${DocumentsSchema.documentId} = ? '
      'AND ${DocumentsSchema.documentWorkspaceId} = ? '
      'AND ${DocumentsSchema.documentDeletedAt} IS NULL '
      'LIMIT 1',
      [documentId, workspaceId],
    );
    return rows.isNotEmpty;
  }
}
