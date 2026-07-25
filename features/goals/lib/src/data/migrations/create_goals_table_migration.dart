import 'package:feature_goals/src/data/schema/goals_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `goals` table and its supporting indexes.
///
/// [Goal.status] is a `TEXT` column constrained to the values of the
/// actual `GoalStatus` enum (`active`, `completed`, `archived` — see
/// `goal_status.dart`). Mirrors Finance's
/// `CreateAccountsTableMigration` and Tasks' `CreateTasksTableMigration`
/// exactly, including their current status: declared for parity and as
/// schema-as-code documentation, not yet wired into a runtime migration
/// runner, since the active executor is the hand-rolled in-memory/file-backed
/// engine rather than a real SQL engine (same as Finance/Tasks today).
///
/// Soft delete is represented by nullable [GoalsSchema.goalDeletedAt]
/// rather than a boolean flag, so the deletion moment is recoverable for
/// audit/debugging — the [Goal] entity itself has no such field; this is
/// purely a storage-layer concern.
final class CreateGoalsTableMigration extends Migration {
  const CreateGoalsTableMigration() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${GoalsSchema.goalsTable} (
        ${GoalsSchema.goalId}              TEXT    PRIMARY KEY,
        ${GoalsSchema.goalWorkspaceId}      TEXT    NOT NULL,
        ${GoalsSchema.goalName}             TEXT    NOT NULL CHECK (length(trim(${GoalsSchema.goalName})) > 0),
        ${GoalsSchema.goalTargetValue}      REAL    NOT NULL CHECK (${GoalsSchema.goalTargetValue} > 0),
        ${GoalsSchema.goalStatus}           TEXT    NOT NULL CHECK (${GoalsSchema.goalStatus} IN ('active', 'completed', 'archived')),
        ${GoalsSchema.goalDescription}      TEXT,
        ${GoalsSchema.goalUnit}             TEXT,
        ${GoalsSchema.goalCurrentProgress}  REAL    NOT NULL DEFAULT 0,
        ${GoalsSchema.goalTargetDate}       TEXT,
        ${GoalsSchema.goalCreatedAt}        TEXT    NOT NULL,
        ${GoalsSchema.goalUpdatedAt}        TEXT    NOT NULL,
        ${GoalsSchema.goalDeletedAt}        TEXT
      )
    ''');

    // Serves IGoalRepository.findAll(workspaceId) and general workspace scoping.
    await ctx.execute('''
      CREATE INDEX idx_goals_workspace_id
      ON ${GoalsSchema.goalsTable} (${GoalsSchema.goalWorkspaceId})
    ''');

    // Serves IGoalRepository.findByStatus(workspaceId, status); excludes
    // soft-deleted rows.
    await ctx.execute('''
      CREATE INDEX idx_goals_workspace_status
      ON ${GoalsSchema.goalsTable} (${GoalsSchema.goalWorkspaceId}, ${GoalsSchema.goalStatus})
      WHERE ${GoalsSchema.goalDeletedAt} IS NULL
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_goals_workspace_status');
    await ctx.execute('DROP INDEX IF EXISTS idx_goals_workspace_id');
    await ctx.execute('DROP TABLE IF EXISTS ${GoalsSchema.goalsTable}');
  }
}
