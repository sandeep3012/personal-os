import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_page.dart';
import 'package:feature_tasks/src/domain/value_objects/task_query.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Task persistence, expressed in domain terms (DOC-032 §7.1).
///
/// Implementations are internal to the Tasks feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-delete is the only supported removal strategy, mirroring Finance
/// exactly (DOC-032 §10 Business Rule 6) — this is a separate mechanism from
/// the domain-visible `TaskStatus.archived` state.
abstract interface class ITaskRepository {
  /// Returns the [Task] with [id] within [workspaceId], or `null` if no
  /// matching, non-deleted task exists.
  FutureResult<Task?> findById(TaskId id, {required String workspaceId});

  /// Returns all non-deleted tasks within [workspaceId], regardless of
  /// status (DOC-032 §12 — filtering by status is [SearchTasksUseCase]'s
  /// responsibility, not this method's).
  ///
  /// Returns an empty list when no tasks exist — never fails for an empty
  /// workspace.
  FutureResult<List<Task>> findAll({required String workspaceId});

  /// Returns all non-deleted tasks within [workspaceId] whose status equals
  /// [status].
  FutureResult<List<Task>> findByStatus(
    TaskStatus status, {
    required String workspaceId,
  });

  /// Executes [query] and returns the matching page of tasks alongside the
  /// total match count (pre-pagination). Mirrors
  /// `ITransactionRepository.query`.
  FutureResult<TaskPage> search(TaskQuery query);

  /// Persists [task]. Creates it if it is new; updates it if it already
  /// exists.
  FutureResult<void> save(Task task);

  /// Marks the task identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the task has already been removed.
  /// Soft-delete only; hard deletion is not supported (mirrors Finance).
  FutureResult<void> softDelete(TaskId id, {required String workspaceId});
}
