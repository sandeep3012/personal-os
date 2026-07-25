import 'package:feature_habits/src/data/schema/habits_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `habits` table and its supporting indexes.
///
/// [Habit.status] is a `TEXT` column constrained to the values of the
/// actual `HabitStatus` enum (`active`, `archived` — see
/// `habit_status.dart`); [Habit.frequency] is similarly constrained to the
/// `HabitFrequency` enum (`daily`, `weekly`). Mirrors Finance's
/// `CreateAccountsTableMigration` and Tasks' `CreateTasksTableMigration`
/// exactly, including their current status: declared for parity and as
/// schema-as-code documentation, not yet wired into a runtime migration
/// runner, since the active executor is the hand-rolled in-memory/file-backed
/// engine rather than a real SQL engine (same as Finance/Tasks today).
///
/// Soft delete is represented by nullable [HabitsSchema.habitDeletedAt]
/// rather than a boolean flag, so the deletion moment is recoverable for
/// audit/debugging — the [Habit] entity itself has no such field; this is
/// purely a storage-layer concern.
final class CreateHabitsTableMigration extends Migration {
  const CreateHabitsTableMigration() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${HabitsSchema.habitsTable} (
        ${HabitsSchema.habitId}              TEXT    PRIMARY KEY,
        ${HabitsSchema.habitWorkspaceId}      TEXT    NOT NULL,
        ${HabitsSchema.habitName}             TEXT    NOT NULL CHECK (length(trim(${HabitsSchema.habitName})) > 0),
        ${HabitsSchema.habitFrequency}        TEXT    NOT NULL CHECK (${HabitsSchema.habitFrequency} IN ('daily', 'weekly')),
        ${HabitsSchema.habitStatus}           TEXT    NOT NULL CHECK (${HabitsSchema.habitStatus} IN ('active', 'archived')),
        ${HabitsSchema.habitDescription}      TEXT,
        ${HabitsSchema.habitCurrentStreak}    INTEGER NOT NULL DEFAULT 0,
        ${HabitsSchema.habitLongestStreak}    INTEGER NOT NULL DEFAULT 0,
        ${HabitsSchema.habitCompletionLog}    TEXT    NOT NULL DEFAULT '[]',
        ${HabitsSchema.habitLastCompletedAt}  TEXT,
        ${HabitsSchema.habitCreatedAt}        TEXT    NOT NULL,
        ${HabitsSchema.habitUpdatedAt}        TEXT    NOT NULL,
        ${HabitsSchema.habitDeletedAt}        TEXT
      )
    ''');

    // Serves IHabitRepository.findAll(workspaceId) and general workspace scoping.
    await ctx.execute('''
      CREATE INDEX idx_habits_workspace_id
      ON ${HabitsSchema.habitsTable} (${HabitsSchema.habitWorkspaceId})
    ''');

    // Serves IHabitRepository.findByStatus(workspaceId, status); excludes
    // soft-deleted rows.
    await ctx.execute('''
      CREATE INDEX idx_habits_workspace_status
      ON ${HabitsSchema.habitsTable} (${HabitsSchema.habitWorkspaceId}, ${HabitsSchema.habitStatus})
      WHERE ${HabitsSchema.habitDeletedAt} IS NULL
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_habits_workspace_status');
    await ctx.execute('DROP INDEX IF EXISTS idx_habits_workspace_id');
    await ctx.execute('DROP TABLE IF EXISTS ${HabitsSchema.habitsTable}');
  }
}
