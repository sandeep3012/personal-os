import 'package:feature_goals/src/data/dao/goal_dao.dart';
import 'package:feature_goals/src/data/mappers/goal_mapper.dart';
import 'package:feature_goals/src/data/models/goal_query_filter.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_page.dart';
import 'package:feature_goals/src/domain/value_objects/goal_query.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [IGoalRepository].
///
/// Pure orchestration: delegates all SQL to [GoalDao] and all entity/row
/// conversion to [GoalMapper]. Never builds SQL, never applies business
/// rules — those responsibilities belong to the DAO, the mapper, and the
/// domain entity respectively. Mirrors Finance's `AccountRepository`/
/// `TransactionRepository`.
final class GoalRepository implements IGoalRepository {
  const GoalRepository({
    required GoalDao goalDao,
    required GoalMapper goalMapper,
  })  : _goalDao = goalDao,
        _goalMapper = goalMapper;

  final GoalDao _goalDao;
  final GoalMapper _goalMapper;

  @override
  FutureResult<Goal?> findById(
    GoalId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _goalDao.findById(id.value, workspaceId: workspaceId);
      if (row == null) return const Result.success(null);
      return Result.success(_goalMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Goal>> findAll({required String workspaceId}) async {
    try {
      final rows = await _goalDao.findAll(workspaceId);
      return Result.success(rows.map(_goalMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Goal>> findByStatus(
    GoalStatus status, {
    required String workspaceId,
  }) async {
    try {
      final rows = await _goalDao.findByStatus(
        status.name,
        workspaceId: workspaceId,
      );
      return Result.success(rows.map(_goalMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<GoalPage> search(GoalQuery query) async {
    try {
      final filter = GoalQueryFilter(
        workspaceId: query.workspaceId,
        status: query.status?.name,
        nameContains: query.nameContains,
        pageIndex: query.pageIndex,
        pageSize: query.pageSize,
      );
      final result = await _goalDao.query(filter);
      final end = (query.pageIndex + 1) * query.pageSize;

      return Result.success(GoalPage(
        items: result.items.map(_goalMapper.toEntity).toList(),
        totalCount: result.totalCount,
        hasNextPage: end < result.totalCount,
      ));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Goal goal) async {
    try {
      final row = _goalMapper.toRow(goal);
      final alreadyExists = await _goalDao.exists(
        goal.id.value,
        workspaceId: goal.workspaceId,
      );
      if (alreadyExists) {
        await _goalDao.update(row);
      } else {
        await _goalDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    GoalId id, {
    required String workspaceId,
  }) async {
    try {
      await _goalDao.softDelete(
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
  /// [GoalsException] so callers never see a raw database or
  /// persistence-layer exception.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return GoalsException(
      message: 'Goal repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
