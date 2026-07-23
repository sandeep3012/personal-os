/// Table and column name constants for the Habits SQLite schema.
///
/// Single source of truth for identifiers referenced by both the schema
/// migration and the repository/DAO layer — mirrors Finance's
/// `FinanceSchema` and Tasks' `TasksSchema`.
abstract final class HabitsSchema {
  static const habitsTable = 'habits';

  static const habitId = 'habit_id';
  static const habitWorkspaceId = 'workspace_id';
  static const habitName = 'name';
  static const habitFrequency = 'frequency';
  static const habitStatus = 'status';
  static const habitDescription = 'description';
  static const habitCurrentStreak = 'current_streak';
  static const habitLongestStreak = 'longest_streak';
  static const habitCompletionLog = 'completion_log';
  static const habitLastCompletedAt = 'last_completed_at';
  static const habitCreatedAt = 'created_at';
  static const habitUpdatedAt = 'updated_at';
  static const habitDeletedAt = 'deleted_at';

  // ── Column ordering (DAO insert/update column lists) ─────────────────────

  static const List<String> habitColumns = [
    habitId,
    habitWorkspaceId,
    habitName,
    habitFrequency,
    habitStatus,
    habitDescription,
    habitCurrentStreak,
    habitLongestStreak,
    habitCompletionLog,
    habitLastCompletedAt,
    habitCreatedAt,
    habitUpdatedAt,
    habitDeletedAt,
  ];
}
