import 'dart:convert';

import 'package:feature_habits/habits.dart';

/// Seeds a fresh [IHabitDatabaseExecutor] with realistic Habits sample data
/// for Demo Mode. Mirrors `DemoTaskSeedData`/`DemoFinanceSeedData` exactly —
/// writes directly via `INSERT INTO ...`, the same seam `apps/mobile`'s own
/// bootstrap tests use, since `feature_habits`'s internal schema/DAO classes
/// aren't part of its public barrel.
abstract final class DemoHabitSeedData {
  /// Inserts a realistic demo dataset into [executor] for [workspaceId]: a
  /// mix of daily/weekly habits with active streaks and one archived habit
  /// — archiving is a user action, but including one demonstrates the
  /// "archived habits are hidden from the list" behavior in Demo Mode too.
  static Future<void> seed(
    IHabitDatabaseExecutor executor, {
    required String workspaceId,
  }) async {
    final now = DateTime.now();
    String daysAgo(int days) =>
        DateTime(now.year, now.month, now.day).subtract(Duration(days: days)).toIso8601String();
    String dateOnlyDaysAgo(int days) =>
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: days))
            .toIso8601String()
            .split('T')
            .first;
    final createdAt = now.toIso8601String();

    var seq = 0;
    String nextId() => 'demo-habit-${++seq}';

    Future<void> insertHabit({
      required String name,
      required String frequency,
      String status = 'active',
      String? description,
      required int currentStreak,
      required int longestStreak,
      required List<String> completionLog,
      String? lastCompletedAt,
    }) =>
        executor.execute(
          'INSERT INTO habits '
          '(habit_id, workspace_id, name, frequency, status, description, '
          'current_streak, longest_streak, completion_log, last_completed_at, '
          'created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            nextId(),
            workspaceId,
            name,
            frequency,
            status,
            description,
            currentStreak,
            longestStreak,
            jsonEncode(completionLog),
            lastCompletedAt,
            createdAt,
            createdAt,
            null,
          ],
        );

    await insertHabit(
      name: 'Drink 8 glasses of water',
      frequency: 'daily',
      description: 'Stay hydrated throughout the day',
      currentStreak: 5,
      longestStreak: 12,
      completionLog: [
        for (var i = 4; i >= 0; i--) dateOnlyDaysAgo(i),
      ],
      lastCompletedAt: daysAgo(0),
    );
    await insertHabit(
      name: 'Morning meditation',
      frequency: 'daily',
      description: '10 minutes of mindfulness',
      currentStreak: 2,
      longestStreak: 21,
      completionLog: [dateOnlyDaysAgo(1), dateOnlyDaysAgo(0)],
      lastCompletedAt: daysAgo(0),
    );
    await insertHabit(
      name: 'Go for a run',
      frequency: 'weekly',
      currentStreak: 3,
      longestStreak: 3,
      completionLog: [dateOnlyDaysAgo(14), dateOnlyDaysAgo(7), dateOnlyDaysAgo(0)],
      lastCompletedAt: daysAgo(0),
    );
    await insertHabit(
      name: 'Read for 30 minutes',
      frequency: 'daily',
      description: 'Fiction or nonfiction, doesn\'t matter',
      currentStreak: 0,
      longestStreak: 8,
      completionLog: [dateOnlyDaysAgo(5)],
      lastCompletedAt: daysAgo(5),
    );
    await insertHabit(
      name: 'Weekly meal prep',
      frequency: 'weekly',
      currentStreak: 1,
      longestStreak: 4,
      completionLog: [dateOnlyDaysAgo(0)],
      lastCompletedAt: daysAgo(0),
    );
    await insertHabit(
      name: 'Learn Spanish (Duolingo)',
      frequency: 'daily',
      status: 'archived',
      currentStreak: 0,
      longestStreak: 15,
      completionLog: const [],
    );
  }
}
