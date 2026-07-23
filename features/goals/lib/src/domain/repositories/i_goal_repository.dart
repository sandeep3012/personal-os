import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_page.dart';
import 'package:feature_goals/src/domain/value_objects/goal_query.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Goal persistence, expressed in domain terms (DOC-032 §7.1).
///
/// Implementations are internal to the Goals feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-delete is the only supported removal strategy, mirroring Finance
/// exactly (DOC-032 §10 Business Rule 6) — this is a separate mechanism from
/// the domain-visible `GoalStatus.archived` state.
abstract interface class IGoalRepository {
  /// Returns the [Goal] with [id] within [workspaceId], or `null` if no
  /// matching, non-deleted goal exists.
  FutureResult<Goal?> findById(GoalId id, {required String workspaceId});

  /// Returns all non-deleted goals within [workspaceId], regardless of
  /// status (DOC-032 §12 — filtering by status is [SearchGoalsUseCase]'s
  /// responsibility, not this method's).
  ///
  /// Returns an empty list when no goals exist — never fails for an empty
  /// workspace.
  FutureResult<List<Goal>> findAll({required String workspaceId});

  /// Returns all non-deleted goals within [workspaceId] whose status equals
  /// [status].
  FutureResult<List<Goal>> findByStatus(
    GoalStatus status, {
    required String workspaceId,
  });

  /// Executes [query] and returns the matching page of goals alongside the
  /// total match count (pre-pagination). Mirrors
  /// `ITransactionRepository.query`.
  FutureResult<GoalPage> search(GoalQuery query);

  /// Persists [goal]. Creates it if it is new; updates it if it already
  /// exists.
  FutureResult<void> save(Goal goal);

  /// Marks the goal identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the goal has already been removed.
  /// Soft-delete only; hard deletion is not supported (mirrors Finance).
  FutureResult<void> softDelete(GoalId id, {required String workspaceId});
}
