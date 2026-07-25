import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_page.dart';
import 'package:feature_habits/src/domain/value_objects/habit_query.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Habit persistence, expressed in domain terms (DOC-032 §7.1).
///
/// Implementations are internal to the Habits feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-delete is the only supported removal strategy, mirroring Finance
/// exactly (DOC-032 §10 Business Rule 6) — this is a separate mechanism from
/// the domain-visible `HabitStatus.archived` state.
abstract interface class IHabitRepository {
  /// Returns the [Habit] with [id] within [workspaceId], or `null` if no
  /// matching, non-deleted habit exists.
  FutureResult<Habit?> findById(HabitId id, {required String workspaceId});

  /// Returns all non-deleted habits within [workspaceId], regardless of
  /// status (DOC-032 §12 — filtering by status is [SearchHabitsUseCase]'s
  /// responsibility, not this method's).
  ///
  /// Returns an empty list when no habits exist — never fails for an empty
  /// workspace.
  FutureResult<List<Habit>> findAll({required String workspaceId});

  /// Returns all non-deleted habits within [workspaceId] whose status equals
  /// [status].
  FutureResult<List<Habit>> findByStatus(
    HabitStatus status, {
    required String workspaceId,
  });

  /// Executes [query] and returns the matching page of habits alongside the
  /// total match count (pre-pagination). Mirrors
  /// `ITransactionRepository.query`.
  FutureResult<HabitPage> search(HabitQuery query);

  /// Persists [habit]. Creates it if it is new; updates it if it already
  /// exists.
  FutureResult<void> save(Habit habit);

  /// Marks the habit identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the habit has already been removed.
  /// Soft-delete only; hard deletion is not supported (mirrors Finance).
  FutureResult<void> softDelete(HabitId id, {required String workspaceId});
}
