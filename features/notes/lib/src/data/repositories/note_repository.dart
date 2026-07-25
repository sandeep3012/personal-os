import 'package:feature_notes/src/data/dao/note_dao.dart';
import 'package:feature_notes/src/data/mappers/note_mapper.dart';
import 'package:feature_notes/src/data/models/note_query_filter.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_page.dart';
import 'package:feature_notes/src/domain/value_objects/note_query.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [INoteRepository].
///
/// Pure orchestration: delegates all SQL to [NoteDao] and all entity/row
/// conversion to [NoteMapper]. Never builds SQL, never applies business
/// rules — those responsibilities belong to the DAO, the mapper, and the
/// domain entity respectively. Mirrors Goals' `GoalRepository`.
final class NoteRepository implements INoteRepository {
  const NoteRepository({
    required NoteDao noteDao,
    required NoteMapper noteMapper,
  })  : _noteDao = noteDao,
        _noteMapper = noteMapper;

  final NoteDao _noteDao;
  final NoteMapper _noteMapper;

  @override
  FutureResult<Note?> findById(
    NoteId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _noteDao.findById(id.value, workspaceId: workspaceId);
      if (row == null) return const Result.success(null);
      return Result.success(_noteMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Note>> findAll({required String workspaceId}) async {
    try {
      final rows = await _noteDao.findAll(workspaceId);
      return Result.success(rows.map(_noteMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Note>> findByStatus(
    NoteStatus status, {
    required String workspaceId,
  }) async {
    try {
      final rows = await _noteDao.findByStatus(
        status.name,
        workspaceId: workspaceId,
      );
      return Result.success(rows.map(_noteMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<NotePage> search(NoteQuery query) async {
    try {
      final filter = NoteQueryFilter(
        workspaceId: query.workspaceId,
        status: query.status?.name,
        titleContains: query.titleContains,
        contentContains: query.contentContains,
        tagContains: query.tagContains,
        pageIndex: query.pageIndex,
        pageSize: query.pageSize,
      );
      final result = await _noteDao.query(filter);
      final end = (query.pageIndex + 1) * query.pageSize;

      return Result.success(NotePage(
        items: result.items.map(_noteMapper.toEntity).toList(),
        totalCount: result.totalCount,
        hasNextPage: end < result.totalCount,
      ));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Note note) async {
    try {
      final row = _noteMapper.toRow(note);
      final alreadyExists = await _noteDao.exists(
        note.id.value,
        workspaceId: note.workspaceId,
      );
      if (alreadyExists) {
        await _noteDao.update(row);
      } else {
        await _noteDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    NoteId id, {
    required String workspaceId,
  }) async {
    try {
      await _noteDao.softDelete(
        id.value,
        workspaceId: workspaceId,
        deletedAt: DateTime.now(),
      );
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  /// Translates any failure raised by the DAO or mapper into a
  /// [NotesException] so callers never see a raw database or
  /// persistence-layer exception.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return NotesException(
      message: 'Note repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
