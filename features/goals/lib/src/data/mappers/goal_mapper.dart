import 'package:feature_goals/src/data/models/goal_row.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:feature_goals/src/domain/value_objects/goal_target_date.dart';

/// Converts between the domain [Goal] entity and the persistence [GoalRow]
/// model. Pure conversion only — no validation, no repository calls, no SQL,
/// no business rules. Mirrors Finance's `AccountMapper`/`TransactionMapper`
/// and Habits' `HabitMapper`.
///
/// [Goal] never represents a soft-deleted row: [GoalDao]'s read methods
/// already exclude soft-deleted rows (`deleted_at IS NULL`), so a domain
/// [Goal] instance can never have been loaded from a deleted row in the
/// first place. Consequently [toRow] always sets [GoalRow.deletedAt] to
/// `null`.
final class GoalMapper {
  const GoalMapper();

  /// Converts a persisted [GoalRow] to a domain [Goal].
  ///
  /// Throws [GoalsException] if [GoalRow.status] does not correspond to a
  /// value this mapper recognizes — corrupted or unsupported persisted data
  /// must fail loudly rather than be silently coerced.
  Goal toEntity(GoalRow row) {
    return Goal(
      id: GoalId(row.goalId),
      workspaceId: row.workspaceId,
      name: row.name,
      targetValue: row.targetValue,
      currentProgress: row.currentProgress,
      status: _statusFromColumnValue(row.status),
      description: row.description,
      unit: row.unit,
      targetDate: row.targetDate == null ? null : GoalTargetDate(row.targetDate!),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Goal] to a persistable [GoalRow].
  GoalRow toRow(Goal goal) {
    return GoalRow(
      goalId: goal.id.value,
      workspaceId: goal.workspaceId,
      name: goal.name,
      targetValue: goal.targetValue,
      currentProgress: goal.currentProgress,
      status: goal.status.name,
      description: goal.description,
      unit: goal.unit,
      targetDate: goal.targetDate?.value,
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt,
      deletedAt: null,
    );
  }

  GoalStatus _statusFromColumnValue(String value) {
    for (final status in GoalStatus.values) {
      if (status.name == value) return status;
    }
    throw GoalsException(
      message: 'Unrecognized status value persisted: "$value"',
    );
  }
}
