import 'package:feature_notes/src/data/database/i_note_database_executor.dart';
import 'package:feature_notes/src/data/models/note_query_filter.dart';
import 'package:feature_notes/src/data/models/note_row.dart';
import 'package:feature_notes/src/data/schema/notes_schema.dart';

const _totalCountAlias = 'total';

/// Direct SQL access to the `notes` table.
///
/// Operates exclusively on [NoteRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`), mirroring Goals' `GoalDao`.
final class NoteDao {
  const NoteDao(this._executor);

  final INoteDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [NoteRow.noteId] — this method performs no existence check.
  Future<void> insert(NoteRow row) async {
    final map = row.toMap();
    const columns = NotesSchema.noteColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${NotesSchema.notesTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by [NoteRow.noteId].
  Future<void> update(NoteRow row) async {
    final map = row.toMap();
    final updatableColumns =
        NotesSchema.noteColumns.where((c) => c != NotesSchema.noteId).toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${NotesSchema.notesTable} SET $setClause '
      'WHERE ${NotesSchema.noteId} = ?',
      [...updatableColumns.map((c) => map[c]), row.noteId],
    );
  }

  /// Returns the row with [noteId] within [workspaceId], or `null` if no
  /// matching, non-deleted row exists.
  Future<NoteRow?> findById(
    String noteId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${NotesSchema.notesTable} '
      'WHERE ${NotesSchema.noteId} = ? '
      'AND ${NotesSchema.noteWorkspaceId} = ? '
      'AND ${NotesSchema.noteDeletedAt} IS NULL',
      [noteId, workspaceId],
    );
    return rows.isEmpty ? null : NoteRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows within [workspaceId], oldest first.
  Future<List<NoteRow>> findAll(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${NotesSchema.notesTable} '
      'WHERE ${NotesSchema.noteWorkspaceId} = ? '
      'AND ${NotesSchema.noteDeletedAt} IS NULL '
      'ORDER BY ${NotesSchema.noteCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(NoteRow.fromMap).toList();
  }

  /// Returns all non-deleted rows within [workspaceId] whose `status` column
  /// equals [status], oldest first.
  Future<List<NoteRow>> findByStatus(
    String status, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${NotesSchema.notesTable} '
      'WHERE ${NotesSchema.noteWorkspaceId} = ? '
      'AND ${NotesSchema.noteStatus} = ? '
      'AND ${NotesSchema.noteDeletedAt} IS NULL '
      'ORDER BY ${NotesSchema.noteCreatedAt} ASC',
      [workspaceId, status],
    );
    return rows.map(NoteRow.fromMap).toList();
  }

  /// Executes [filter] and returns the matching page of rows alongside the
  /// total match count (pre-pagination). Mirrors `GoalDao.query`.
  Future<({List<NoteRow> items, int totalCount})> query(
    NoteQueryFilter filter,
  ) async {
    final where = StringBuffer(
      '${NotesSchema.noteWorkspaceId} = ? '
      'AND ${NotesSchema.noteDeletedAt} IS NULL',
    );
    final args = <Object?>[filter.workspaceId];

    if (filter.status != null) {
      where.write(' AND ${NotesSchema.noteStatus} = ?');
      args.add(filter.status);
    }
    if (filter.titleContains != null && filter.titleContains!.isNotEmpty) {
      where.write(' AND LOWER(${NotesSchema.noteTitle}) LIKE ?');
      args.add('%${filter.titleContains!.toLowerCase()}%');
    }
    if (filter.contentContains != null && filter.contentContains!.isNotEmpty) {
      where.write(' AND LOWER(${NotesSchema.noteContent}) LIKE ?');
      args.add('%${filter.contentContains!.toLowerCase()}%');
    }
    if (filter.tagContains != null && filter.tagContains!.isNotEmpty) {
      where.write(' AND LOWER(${NotesSchema.noteTags}) LIKE ?');
      args.add('%${filter.tagContains!.toLowerCase()}%');
    }

    final countRows = await _executor.query(
      'SELECT COUNT(*) AS $_totalCountAlias '
      'FROM ${NotesSchema.notesTable} WHERE $where',
      args,
    );
    final totalCount = countRows.first[_totalCountAlias]! as int;

    final pagedRows = await _executor.query(
      'SELECT * FROM ${NotesSchema.notesTable} WHERE $where '
      'ORDER BY ${NotesSchema.noteCreatedAt} DESC '
      'LIMIT ? OFFSET ?',
      [...args, filter.pageSize, filter.pageIndex * filter.pageSize],
    );

    return (
      items: pagedRows.map(NoteRow.fromMap).toList(),
      totalCount: totalCount,
    );
  }

  /// Sets [NotesSchema.noteDeletedAt] and [NotesSchema.noteUpdatedAt] to
  /// [deletedAt]. Idempotent — matches zero rows harmlessly if [noteId] does
  /// not exist or is already soft-deleted.
  Future<void> softDelete(
    String noteId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${NotesSchema.notesTable} '
      'SET ${NotesSchema.noteDeletedAt} = ?, ${NotesSchema.noteUpdatedAt} = ? '
      'WHERE ${NotesSchema.noteId} = ? '
      'AND ${NotesSchema.noteWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        noteId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [noteId] exists within
  /// [workspaceId].
  Future<bool> exists(String noteId, {required String workspaceId}) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${NotesSchema.notesTable} '
      'WHERE ${NotesSchema.noteId} = ? '
      'AND ${NotesSchema.noteWorkspaceId} = ? '
      'AND ${NotesSchema.noteDeletedAt} IS NULL '
      'LIMIT 1',
      [noteId, workspaceId],
    );
    return rows.isNotEmpty;
  }
}
