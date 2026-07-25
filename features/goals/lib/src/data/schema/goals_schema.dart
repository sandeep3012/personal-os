/// Table and column name constants for the Goals SQLite schema.
///
/// Single source of truth for identifiers referenced by both the schema
/// migration and the repository/DAO layer — mirrors Finance's
/// `FinanceSchema` and Habits' `HabitsSchema`.
abstract final class GoalsSchema {
  static const goalsTable = 'goals';

  static const goalId = 'goal_id';
  static const goalWorkspaceId = 'workspace_id';
  static const goalName = 'name';
  static const goalTargetValue = 'target_value';
  static const goalCurrentProgress = 'current_progress';
  static const goalStatus = 'status';
  static const goalDescription = 'description';
  static const goalUnit = 'unit';
  static const goalTargetDate = 'target_date';
  static const goalCreatedAt = 'created_at';
  static const goalUpdatedAt = 'updated_at';
  static const goalDeletedAt = 'deleted_at';

  // ── Column ordering (DAO insert/update column lists) ─────────────────────

  static const List<String> goalColumns = [
    goalId,
    goalWorkspaceId,
    goalName,
    goalTargetValue,
    goalCurrentProgress,
    goalStatus,
    goalDescription,
    goalUnit,
    goalTargetDate,
    goalCreatedAt,
    goalUpdatedAt,
    goalDeletedAt,
  ];
}
