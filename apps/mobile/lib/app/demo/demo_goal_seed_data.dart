import 'package:feature_goals/goals.dart';

/// Seeds a fresh [IGoalDatabaseExecutor] with realistic Goals sample data
/// for Demo Mode. Mirrors `DemoHabitSeedData`/`DemoTaskSeedData` exactly —
/// writes directly via `INSERT INTO ...`, the same seam `apps/mobile`'s own
/// bootstrap tests use, since `feature_goals`'s internal schema/DAO classes
/// aren't part of its public barrel.
abstract final class DemoGoalSeedData {
  /// Inserts a realistic demo dataset into [executor] for [workspaceId]: a
  /// mix of in-progress, completed, and one archived goal — archiving is a
  /// user action, but including one demonstrates the "archived goals are
  /// hidden from the list" behavior in Demo Mode too.
  static Future<void> seed(
    IGoalDatabaseExecutor executor, {
    required String workspaceId,
  }) async {
    final now = DateTime.now();
    final createdAt = now.toIso8601String();

    var seq = 0;
    String nextId() => 'demo-goal-${++seq}';

    Future<void> insertGoal({
      required String name,
      required double targetValue,
      required double currentProgress,
      String status = 'active',
      String? description,
      String? unit,
      String? targetDate,
    }) =>
        executor.execute(
          'INSERT INTO goals '
          '(goal_id, workspace_id, name, target_value, current_progress, '
          'status, description, unit, target_date, created_at, updated_at, '
          'deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            nextId(),
            workspaceId,
            name,
            targetValue,
            currentProgress,
            status,
            description,
            unit,
            targetDate,
            createdAt,
            createdAt,
            null,
          ],
        );

    await insertGoal(
      name: 'Run a marathon',
      targetValue: 42,
      currentProgress: 18,
      description: 'Training for the fall marathon',
      unit: 'km',
      targetDate: DateTime(now.year, now.month + 3, now.day).toIso8601String(),
    );
    await insertGoal(
      name: 'Save for vacation',
      targetValue: 3000,
      currentProgress: 1200,
      description: 'Trip to Japan next spring',
      unit: 'USD',
    );
    await insertGoal(
      name: 'Read 24 books this year',
      targetValue: 24,
      currentProgress: 24,
      status: 'completed',
      unit: 'books',
    );
    await insertGoal(
      name: 'Learn conversational Spanish',
      targetValue: 100,
      currentProgress: 40,
      unit: 'lessons',
    );
    await insertGoal(
      name: 'Old gym goal',
      targetValue: 50,
      currentProgress: 10,
      status: 'archived',
      unit: 'sessions',
    );
  }
}
