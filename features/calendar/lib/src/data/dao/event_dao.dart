import 'package:feature_calendar/src/data/database/i_event_database_executor.dart';
import 'package:feature_calendar/src/data/models/event_query_filter.dart';
import 'package:feature_calendar/src/data/models/event_row.dart';
import 'package:feature_calendar/src/data/schema/events_schema.dart';

const _totalCountAlias = 'total';

/// Direct SQL access to the `events` table.
///
/// Operates exclusively on [EventRow] — no domain types are accepted or
/// returned. Contains no business validation, no entity construction, no
/// orchestration. Every read method excludes soft-deleted rows
/// (`deleted_at IS NULL`), mirroring Notes' `NoteDao`.
final class EventDao {
  const EventDao(this._executor);

  final IEventDatabaseExecutor _executor;

  /// Inserts a new row. Callers are responsible for supplying a unique
  /// [EventRow.eventId] — this method performs no existence check.
  Future<void> insert(EventRow row) async {
    final map = row.toMap();
    const columns = EventsSchema.eventColumns;
    final placeholders = List.filled(columns.length, '?').join(', ');

    await _executor.execute(
      'INSERT INTO ${EventsSchema.eventsTable} '
      '(${columns.join(', ')}) VALUES ($placeholders)',
      columns.map((c) => map[c]).toList(),
    );
  }

  /// Overwrites every column of the row identified by [EventRow.eventId].
  Future<void> update(EventRow row) async {
    final map = row.toMap();
    final updatableColumns =
        EventsSchema.eventColumns.where((c) => c != EventsSchema.eventId).toList();
    final setClause = updatableColumns.map((c) => '$c = ?').join(', ');

    await _executor.execute(
      'UPDATE ${EventsSchema.eventsTable} SET $setClause '
      'WHERE ${EventsSchema.eventId} = ?',
      [...updatableColumns.map((c) => map[c]), row.eventId],
    );
  }

  /// Returns the row with [eventId] within [workspaceId], or `null` if no
  /// matching, non-deleted row exists.
  Future<EventRow?> findById(
    String eventId, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${EventsSchema.eventsTable} '
      'WHERE ${EventsSchema.eventId} = ? '
      'AND ${EventsSchema.eventWorkspaceId} = ? '
      'AND ${EventsSchema.eventDeletedAt} IS NULL',
      [eventId, workspaceId],
    );
    return rows.isEmpty ? null : EventRow.fromMap(rows.first);
  }

  /// Returns all non-deleted rows within [workspaceId], oldest first.
  Future<List<EventRow>> findAll(String workspaceId) async {
    final rows = await _executor.query(
      'SELECT * FROM ${EventsSchema.eventsTable} '
      'WHERE ${EventsSchema.eventWorkspaceId} = ? '
      'AND ${EventsSchema.eventDeletedAt} IS NULL '
      'ORDER BY ${EventsSchema.eventCreatedAt} ASC',
      [workspaceId],
    );
    return rows.map(EventRow.fromMap).toList();
  }

  /// Returns all non-deleted rows within [workspaceId] whose `status`
  /// column equals [status], oldest first.
  Future<List<EventRow>> findByStatus(
    String status, {
    required String workspaceId,
  }) async {
    final rows = await _executor.query(
      'SELECT * FROM ${EventsSchema.eventsTable} '
      'WHERE ${EventsSchema.eventWorkspaceId} = ? '
      'AND ${EventsSchema.eventStatus} = ? '
      'AND ${EventsSchema.eventDeletedAt} IS NULL '
      'ORDER BY ${EventsSchema.eventCreatedAt} ASC',
      [workspaceId, status],
    );
    return rows.map(EventRow.fromMap).toList();
  }

  /// Executes [filter] and returns the matching page of rows alongside the
  /// total match count (pre-pagination). Mirrors `NoteDao.query`.
  Future<({List<EventRow> items, int totalCount})> query(
    EventQueryFilter filter,
  ) async {
    final where = StringBuffer(
      '${EventsSchema.eventWorkspaceId} = ? '
      'AND ${EventsSchema.eventDeletedAt} IS NULL',
    );
    final args = <Object?>[filter.workspaceId];

    if (filter.status != null) {
      where.write(' AND ${EventsSchema.eventStatus} = ?');
      args.add(filter.status);
    }
    if (filter.titleContains != null && filter.titleContains!.isNotEmpty) {
      where.write(' AND LOWER(${EventsSchema.eventTitle}) LIKE ?');
      args.add('%${filter.titleContains!.toLowerCase()}%');
    }
    if (filter.locationContains != null && filter.locationContains!.isNotEmpty) {
      where.write(' AND LOWER(${EventsSchema.eventLocation}) LIKE ?');
      args.add('%${filter.locationContains!.toLowerCase()}%');
    }

    final countRows = await _executor.query(
      'SELECT COUNT(*) AS $_totalCountAlias '
      'FROM ${EventsSchema.eventsTable} WHERE $where',
      args,
    );
    final totalCount = countRows.first[_totalCountAlias]! as int;

    final pagedRows = await _executor.query(
      'SELECT * FROM ${EventsSchema.eventsTable} WHERE $where '
      'ORDER BY ${EventsSchema.eventCreatedAt} DESC '
      'LIMIT ? OFFSET ?',
      [...args, filter.pageSize, filter.pageIndex * filter.pageSize],
    );

    return (
      items: pagedRows.map(EventRow.fromMap).toList(),
      totalCount: totalCount,
    );
  }

  /// Sets [EventsSchema.eventDeletedAt] and [EventsSchema.eventUpdatedAt] to
  /// [deletedAt]. Idempotent — matches zero rows harmlessly if [eventId]
  /// does not exist or is already soft-deleted.
  Future<void> softDelete(
    String eventId, {
    required String workspaceId,
    required DateTime deletedAt,
  }) async {
    await _executor.execute(
      'UPDATE ${EventsSchema.eventsTable} '
      'SET ${EventsSchema.eventDeletedAt} = ?, ${EventsSchema.eventUpdatedAt} = ? '
      'WHERE ${EventsSchema.eventId} = ? '
      'AND ${EventsSchema.eventWorkspaceId} = ?',
      [
        deletedAt.toIso8601String(),
        deletedAt.toIso8601String(),
        eventId,
        workspaceId,
      ],
    );
  }

  /// Returns `true` if a non-deleted row with [eventId] exists within
  /// [workspaceId].
  Future<bool> exists(String eventId, {required String workspaceId}) async {
    final rows = await _executor.query(
      'SELECT 1 FROM ${EventsSchema.eventsTable} '
      'WHERE ${EventsSchema.eventId} = ? '
      'AND ${EventsSchema.eventWorkspaceId} = ? '
      'AND ${EventsSchema.eventDeletedAt} IS NULL '
      'LIMIT 1',
      [eventId, workspaceId],
    );
    return rows.isNotEmpty;
  }
}
