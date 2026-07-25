import 'package:feature_habits/src/data/dao/habit_dao.dart';
import 'package:feature_habits/src/data/mappers/habit_mapper.dart';
import 'package:feature_habits/src/data/models/habit_query_filter.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_page.dart';
import 'package:feature_habits/src/domain/value_objects/habit_query.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [IHabitRepository].
///
/// Pure orchestration: delegates all SQL to [HabitDao] and all entity/row
/// conversion to [HabitMapper]. Never builds SQL, never applies business
/// rules — those responsibilities belong to the DAO, the mapper, and the
/// domain entity respectively. Mirrors Finance's `AccountRepository`/
/// `TransactionRepository`.
final class HabitRepository implements IHabitRepository {
  const HabitRepository({
    required HabitDao habitDao,
    required HabitMapper habitMapper,
  })  : _habitDao = habitDao,
        _habitMapper = habitMapper;

  final HabitDao _habitDao;
  final HabitMapper _habitMapper;

  @override
  FutureResult<Habit?> findById(
    HabitId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _habitDao.findById(id.value, workspaceId: workspaceId);
      if (row == null) return const Result.success(null);
      return Result.success(_habitMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Habit>> findAll({required String workspaceId}) async {
    try {
      final rows = await _habitDao.findAll(workspaceId);
      return Result.success(rows.map(_habitMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Habit>> findByStatus(
    HabitStatus status, {
    required String workspaceId,
  }) async {
    try {
      final rows = await _habitDao.findByStatus(
        status.name,
        workspaceId: workspaceId,
      );
      return Result.success(rows.map(_habitMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<HabitPage> search(HabitQuery query) async {
    try {
      final filter = HabitQueryFilter(
        workspaceId: query.workspaceId,
        status: query.status?.name,
        nameContains: query.nameContains,
        pageIndex: query.pageIndex,
        pageSize: query.pageSize,
      );
      final result = await _habitDao.query(filter);
      final end = (query.pageIndex + 1) * query.pageSize;

      return Result.success(HabitPage(
        items: result.items.map(_habitMapper.toEntity).toList(),
        totalCount: result.totalCount,
        hasNextPage: end < result.totalCount,
      ));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Habit habit) async {
    try {
      final row = _habitMapper.toRow(habit);
      final alreadyExists = await _habitDao.exists(
        habit.id.value,
        workspaceId: habit.workspaceId,
      );
      if (alreadyExists) {
        await _habitDao.update(row);
      } else {
        await _habitDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    HabitId id, {
    required String workspaceId,
  }) async {
    try {
      await _habitDao.softDelete(
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
  /// [HabitsException] so callers never see a raw database or
  /// persistence-layer exception.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return HabitsException(
      message: 'Habit repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
