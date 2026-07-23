import 'package:feature_tasks/src/data/dao/task_dao.dart';
import 'package:feature_tasks/src/data/mappers/task_mapper.dart';
import 'package:feature_tasks/src/data/models/task_query_filter.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_page.dart';
import 'package:feature_tasks/src/domain/value_objects/task_query.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [ITaskRepository].
///
/// Pure orchestration: delegates all SQL to [TaskDao] and all entity/row
/// conversion to [TaskMapper]. Never builds SQL, never applies business
/// rules — those responsibilities belong to the DAO, the mapper, and the
/// domain entity respectively. Mirrors Finance's `AccountRepository`/
/// `TransactionRepository`.
final class TaskRepository implements ITaskRepository {
  const TaskRepository({
    required TaskDao taskDao,
    required TaskMapper taskMapper,
  })  : _taskDao = taskDao,
        _taskMapper = taskMapper;

  final TaskDao _taskDao;
  final TaskMapper _taskMapper;

  @override
  FutureResult<Task?> findById(
    TaskId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _taskDao.findById(id.value, workspaceId: workspaceId);
      if (row == null) return const Result.success(null);
      return Result.success(_taskMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Task>> findAll({required String workspaceId}) async {
    try {
      final rows = await _taskDao.findAll(workspaceId);
      return Result.success(rows.map(_taskMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Task>> findByStatus(
    TaskStatus status, {
    required String workspaceId,
  }) async {
    try {
      final rows = await _taskDao.findByStatus(
        status.name,
        workspaceId: workspaceId,
      );
      return Result.success(rows.map(_taskMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<TaskPage> search(TaskQuery query) async {
    try {
      final filter = TaskQueryFilter(
        workspaceId: query.workspaceId,
        status: query.status?.name,
        titleContains: query.titleContains,
        pageIndex: query.pageIndex,
        pageSize: query.pageSize,
      );
      final result = await _taskDao.query(filter);
      final end = (query.pageIndex + 1) * query.pageSize;

      return Result.success(TaskPage(
        items: result.items.map(_taskMapper.toEntity).toList(),
        totalCount: result.totalCount,
        hasNextPage: end < result.totalCount,
      ));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Task task) async {
    try {
      final row = _taskMapper.toRow(task);
      final alreadyExists = await _taskDao.exists(
        task.id.value,
        workspaceId: task.workspaceId,
      );
      if (alreadyExists) {
        await _taskDao.update(row);
      } else {
        await _taskDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    TaskId id, {
    required String workspaceId,
  }) async {
    try {
      await _taskDao.softDelete(
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
  /// [TasksException] so callers never see a raw database or
  /// persistence-layer exception.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return TasksException(
      message: 'Task repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
