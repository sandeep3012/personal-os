import 'package:feature_habits/src/data/models/habit_row.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';

/// Converts between the domain [Habit] entity and the persistence [HabitRow]
/// model. Pure conversion only — no validation, no repository calls, no SQL,
/// no business rules. Mirrors Finance's `AccountMapper`/`TransactionMapper`
/// and Tasks' `TaskMapper`.
///
/// [Habit] never represents a soft-deleted row: [HabitDao]'s read methods
/// already exclude soft-deleted rows (`deleted_at IS NULL`), so a domain
/// [Habit] instance can never have been loaded from a deleted row in the
/// first place. Consequently [toRow] always sets [HabitRow.deletedAt] to
/// `null`.
final class HabitMapper {
  const HabitMapper();

  /// Converts a persisted [HabitRow] to a domain [Habit].
  ///
  /// Throws [HabitsException] if [HabitRow.status] or [HabitRow.frequency]
  /// do not correspond to a value this mapper recognizes — corrupted or
  /// unsupported persisted data must fail loudly rather than be silently
  /// coerced.
  Habit toEntity(HabitRow row) {
    return Habit(
      id: HabitId(row.habitId),
      workspaceId: row.workspaceId,
      name: row.name,
      frequency: _frequencyFromColumnValue(row.frequency),
      status: _statusFromColumnValue(row.status),
      description: row.description,
      currentStreak: row.currentStreak,
      longestStreak: row.longestStreak,
      completionLog: row.completionLog.map(DateTime.parse).toList(),
      lastCompletedAt: row.lastCompletedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Habit] to a persistable [HabitRow].
  HabitRow toRow(Habit habit) {
    return HabitRow(
      habitId: habit.id.value,
      workspaceId: habit.workspaceId,
      name: habit.name,
      frequency: habit.frequency.name,
      status: habit.status.name,
      description: habit.description,
      currentStreak: habit.currentStreak,
      longestStreak: habit.longestStreak,
      completionLog: habit.completionLog
          .map((d) => d.toIso8601String().split('T').first)
          .toList(),
      lastCompletedAt: habit.lastCompletedAt,
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
      deletedAt: null,
    );
  }

  HabitStatus _statusFromColumnValue(String value) {
    for (final status in HabitStatus.values) {
      if (status.name == value) return status;
    }
    throw HabitsException(
      message: 'Unrecognized status value persisted: "$value"',
    );
  }

  HabitFrequency _frequencyFromColumnValue(String value) {
    for (final frequency in HabitFrequency.values) {
      if (frequency.name == value) return frequency;
    }
    throw HabitsException(
      message: 'Unrecognized frequency value persisted: "$value"',
    );
  }
}
