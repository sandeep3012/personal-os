import 'dart:convert';

import 'package:feature_habits/src/data/schema/habits_schema.dart';

/// A single, unmapped row from the `habits` table.
///
/// [HabitRow] is a persistence-layer data shape only — it has no business
/// methods, no validation, and no relationship to the domain `Habit` entity.
/// Mapping between [HabitRow] and `Habit` is a repository-layer concern, not
/// a DAO concern. Mirrors Finance's `AccountRow`/`TransactionRow` and Tasks'
/// `TaskRow`.
///
/// [completionLog] is persisted as a JSON array of `YYYY-MM-DD` strings in a
/// single TEXT column ([HabitsSchema.habitCompletionLog]) rather than as a
/// second table — Habits is a single-aggregate feature (there is no
/// independent "Completion" entity with its own identity/lifecycle the way
/// Finance's `Transaction` is independent of `Account`), so a habit's
/// completion history is stored as part of the aggregate it belongs to,
/// mirroring how Tasks keeps every field of its single aggregate on one row.
final class HabitRow {
  const HabitRow({
    required this.habitId,
    required this.workspaceId,
    required this.name,
    required this.frequency,
    required this.status,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionLog,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.lastCompletedAt,
    this.deletedAt,
  });

  final String habitId;
  final String workspaceId;
  final String name;
  final String frequency;
  final String status;
  final String? description;
  final int currentStreak;
  final int longestStreak;

  /// Date-only ISO strings (`YYYY-MM-DD`), ascending.
  final List<String> completionLog;
  final DateTime? lastCompletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Builds a [HabitRow] from a raw SQL result row.
  factory HabitRow.fromMap(Map<String, Object?> map) {
    final lastCompletedValue = map[HabitsSchema.habitLastCompletedAt] as String?;
    final deletedAtValue = map[HabitsSchema.habitDeletedAt] as String?;
    final rawLog = map[HabitsSchema.habitCompletionLog] as String?;
    return HabitRow(
      habitId: map[HabitsSchema.habitId]! as String,
      workspaceId: map[HabitsSchema.habitWorkspaceId]! as String,
      name: map[HabitsSchema.habitName]! as String,
      frequency: map[HabitsSchema.habitFrequency]! as String,
      status: map[HabitsSchema.habitStatus]! as String,
      description: map[HabitsSchema.habitDescription] as String?,
      currentStreak: map[HabitsSchema.habitCurrentStreak]! as int,
      longestStreak: map[HabitsSchema.habitLongestStreak]! as int,
      completionLog: rawLog == null || rawLog.isEmpty
          ? const []
          : (jsonDecode(rawLog) as List).cast<String>(),
      lastCompletedAt:
          lastCompletedValue == null ? null : DateTime.parse(lastCompletedValue),
      createdAt: DateTime.parse(map[HabitsSchema.habitCreatedAt]! as String),
      updatedAt: DateTime.parse(map[HabitsSchema.habitUpdatedAt]! as String),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [HabitsSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        HabitsSchema.habitId: habitId,
        HabitsSchema.habitWorkspaceId: workspaceId,
        HabitsSchema.habitName: name,
        HabitsSchema.habitFrequency: frequency,
        HabitsSchema.habitStatus: status,
        HabitsSchema.habitDescription: description,
        HabitsSchema.habitCurrentStreak: currentStreak,
        HabitsSchema.habitLongestStreak: longestStreak,
        HabitsSchema.habitCompletionLog: jsonEncode(completionLog),
        HabitsSchema.habitLastCompletedAt: lastCompletedAt?.toIso8601String(),
        HabitsSchema.habitCreatedAt: createdAt.toIso8601String(),
        HabitsSchema.habitUpdatedAt: updatedAt.toIso8601String(),
        HabitsSchema.habitDeletedAt: deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRow &&
          other.habitId == habitId &&
          other.workspaceId == workspaceId &&
          other.name == name &&
          other.frequency == frequency &&
          other.status == status &&
          other.description == description &&
          other.currentStreak == currentStreak &&
          other.longestStreak == longestStreak &&
          _listEquals(other.completionLog, completionLog) &&
          other.lastCompletedAt == lastCompletedAt &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        habitId,
        workspaceId,
        name,
        frequency,
        status,
        description,
        currentStreak,
        longestStreak,
        Object.hashAll(completionLog),
        lastCompletedAt,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'HabitRow(habitId: $habitId, name: $name)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
