import 'package:feature_calendar/src/data/dao/event_dao.dart';
import 'package:feature_calendar/src/data/mappers/event_mapper.dart';
import 'package:feature_calendar/src/data/models/event_query_filter.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_page.dart';
import 'package:feature_calendar/src/domain/value_objects/event_query.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [IEventRepository].
///
/// Pure orchestration: delegates all SQL to [EventDao] and all entity/row
/// conversion to [EventMapper]. Never builds SQL, never applies business
/// rules — those responsibilities belong to the DAO, the mapper, and the
/// domain entity respectively. Mirrors Notes' `NoteRepository`.
final class EventRepository implements IEventRepository {
  const EventRepository({
    required EventDao eventDao,
    required EventMapper eventMapper,
  })  : _eventDao = eventDao,
        _eventMapper = eventMapper;

  final EventDao _eventDao;
  final EventMapper _eventMapper;

  @override
  FutureResult<Event?> findById(
    EventId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _eventDao.findById(id.value, workspaceId: workspaceId);
      if (row == null) return const Result.success(null);
      return Result.success(_eventMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Event>> findAll({required String workspaceId}) async {
    try {
      final rows = await _eventDao.findAll(workspaceId);
      return Result.success(rows.map(_eventMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Event>> findByStatus(
    EventStatus status, {
    required String workspaceId,
  }) async {
    try {
      final rows = await _eventDao.findByStatus(
        status.name,
        workspaceId: workspaceId,
      );
      return Result.success(rows.map(_eventMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<EventPage> search(EventQuery query) async {
    try {
      final filter = EventQueryFilter(
        workspaceId: query.workspaceId,
        status: query.status?.name,
        titleContains: query.titleContains,
        locationContains: query.locationContains,
        pageIndex: query.pageIndex,
        pageSize: query.pageSize,
      );
      final result = await _eventDao.query(filter);
      final end = (query.pageIndex + 1) * query.pageSize;

      return Result.success(EventPage(
        items: result.items.map(_eventMapper.toEntity).toList(),
        totalCount: result.totalCount,
        hasNextPage: end < result.totalCount,
      ));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Event event) async {
    try {
      final row = _eventMapper.toRow(event);
      final alreadyExists = await _eventDao.exists(
        event.id.value,
        workspaceId: event.workspaceId,
      );
      if (alreadyExists) {
        await _eventDao.update(row);
      } else {
        await _eventDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    EventId id, {
    required String workspaceId,
  }) async {
    try {
      await _eventDao.softDelete(
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
  /// [CalendarException] so callers never see a raw database or
  /// persistence-layer exception.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return CalendarException(
      message: 'Event repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
