import 'package:feature_tasks/tasks.dart';

/// Seeds a fresh [ITaskDatabaseExecutor] with realistic Tasks sample data
/// for Demo Mode (Milestone 7). Mirrors `DemoFinanceSeedData` exactly —
/// writes directly via `INSERT INTO ...`, the same seam
/// `apps/mobile`'s own bootstrap tests use, since `feature_tasks`'s internal
/// schema/DAO classes aren't part of its public barrel.
abstract final class DemoTaskSeedData {
  /// Inserts a realistic demo dataset into [executor] for [workspaceId]: a
  /// mix of tasks across `todo`, `inProgress`, and `completed` (some
  /// completed today, some earlier) — no `archived` tasks, since archiving
  /// is a user action, not a natural seed state.
  static Future<void> seed(
    ITaskDatabaseExecutor executor, {
    required String workspaceId,
  }) async {
    final now = DateTime.now();
    String daysAgo(int days) =>
        DateTime(now.year, now.month, now.day).subtract(Duration(days: days)).toIso8601String();
    final createdAt = now.toIso8601String();

    var seq = 0;
    String nextId() => 'demo-task-${++seq}';

    Future<void> insertTask({
      required String title,
      required String status,
      String? description,
      String? dueDate,
      String? completedAt,
    }) =>
        executor.execute(
          'INSERT INTO tasks '
          '(task_id, workspace_id, title, status, description, due_date, '
          'completed_at, created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            nextId(),
            workspaceId,
            title,
            status,
            description,
            dueDate,
            completedAt,
            createdAt,
            createdAt,
            null,
          ],
        );

    await insertTask(
      title: 'Review quarterly budget',
      status: 'todo',
      description: 'Compare actuals against plan before the finance sync',
      dueDate: daysAgo(-2), // due in 2 days
    );
    await insertTask(
      title: 'Book dentist appointment',
      status: 'todo',
      dueDate: daysAgo(-5),
    );
    await insertTask(
      title: 'Renew car insurance',
      status: 'todo',
      description: 'Policy expires end of month',
      dueDate: daysAgo(-10),
    );
    await insertTask(
      title: 'Prepare presentation slides',
      status: 'inProgress',
      description: 'Sprint review deck — 80% done',
      dueDate: daysAgo(-1),
    );
    await insertTask(
      title: 'Plan weekend trip',
      status: 'inProgress',
    );
    await insertTask(
      title: 'Pay electricity bill',
      status: 'completed',
      completedAt: daysAgo(0),
    );
    await insertTask(
      title: 'Submit expense report',
      status: 'completed',
      completedAt: daysAgo(0),
    );
    await insertTask(
      title: 'Call plumber about leak',
      status: 'completed',
      completedAt: daysAgo(3),
    );
  }
}
