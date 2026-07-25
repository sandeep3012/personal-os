import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';

/// A Habit aggregate root — a single, standalone unit of recurring personal
/// practice (mirrors DOC-032 §4's Task aggregate shape). There is no owning
/// Project/List/Board entity; grouping, if ever introduced, happens through
/// the platform Entity Linking Service, not through a field on this entity.
///
/// Business invariants enforced here:
/// - [name] must not be empty and must not exceed 200 characters (mirrors
///   Task's title invariant).
/// - Status transitions are only permitted per the approved transition table
///   — enforced by [transitionTo], not by direct field mutation (this class
///   has no public status setter).
/// - Completion recording — including streak continuation/reset and
///   duplicate-same-day rejection — is enforced by [recordCompletion], not
///   by direct field mutation (no public setter for [currentStreak],
///   [longestStreak], or [completionLog] either).
final class Habit {
  Habit({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.frequency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.currentStreak = 0,
    this.longestStreak = 0,
    List<DateTime>? completionLog,
    this.lastCompletedAt,
  }) : completionLog = List.unmodifiable(completionLog ?? const []) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const HabitsException(message: 'Habit name must not be empty');
    }
    if (name.length > 200) {
      throw const HabitsException(
        message: 'Habit name must not exceed 200 characters',
      );
    }
    if (currentStreak < 0 || longestStreak < 0) {
      throw const HabitsException(
        message: 'Habit streak counters must not be negative',
      );
    }
  }

  final HabitId id;
  final String workspaceId;
  final String name;
  final HabitFrequency frequency;
  final HabitStatus status;

  /// Optional free text. Max 1000 characters — enforced at the use-case
  /// validation layer, mirroring how Task validates `description` there
  /// rather than in the entity constructor.
  final String? description;

  /// The length of the current unbroken completion streak, in completions.
  /// `0` if the habit has never been completed, or if the most recent gap
  /// between completions exceeded [HabitFrequency.maxGapInDays].
  final int currentStreak;

  /// The longest [currentStreak] this habit has ever reached — never
  /// decreases.
  final int longestStreak;

  /// The full history of completion dates (date-only, ascending), oldest
  /// first. Populated exclusively by [recordCompletion].
  final List<DateTime> completionLog;

  /// The date-only value of the most recent completion, or `null` if this
  /// habit has never been completed.
  final DateTime? lastCompletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this habit with the supplied fields replaced.
  ///
  /// Does not change [status] — use [transitionTo] for status changes. Does
  /// not change streak/completion fields — use [recordCompletion]. Mirrors
  /// `Task.copyWith` rejecting status as an updatable field.
  Habit copyWith({
    String? name,
    String? description,
    HabitFrequency? frequency,
    DateTime? updatedAt,
  }) =>
      Habit(
        id: id,
        workspaceId: workspaceId,
        name: name ?? this.name,
        frequency: frequency ?? this.frequency,
        status: status,
        description: description ?? this.description,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        completionLog: completionLog,
        lastCompletedAt: lastCompletedAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy of this habit transitioned to [next].
  ///
  /// Throws [HabitsException] if [next] is not reachable from [status] per
  /// the approved transition table:
  ///
  /// ```
  /// active   -> archived
  /// archived -> (none — terminal)
  /// ```
  Habit transitionTo(HabitStatus next, {required DateTime now}) {
    if (!status.canTransitionTo(next)) {
      throw HabitsException(
        message:
            'Cannot transition Habit from ${status.name} to ${next.name}',
      );
    }
    return Habit(
      id: id,
      workspaceId: workspaceId,
      name: name,
      frequency: frequency,
      status: next,
      description: description,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionLog: completionLog,
      lastCompletedAt: lastCompletedAt,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Returns a copy of this habit with a completion recorded for [date]
  /// (time-of-day is discarded — completions are date-only, one per
  /// calendar day).
  ///
  /// Streak logic (the core Habits business rule):
  /// - Throws [HabitsException] if [date]'s calendar day is already present
  ///   in [completionLog] — a habit can only be completed once per day.
  /// - If [lastCompletedAt] is `null` (first-ever completion), or if the gap
  ///   in whole days between [lastCompletedAt] and [date] is within
  ///   [frequency]'s [HabitFrequencyWindow.maxGapInDays], the streak
  ///   continues: [currentStreak] increments by one.
  /// - Otherwise the gap broke the streak: [currentStreak] resets to `1`
  ///   (this completion starts a new streak).
  /// - [longestStreak] is raised to the new [currentStreak] whenever it
  ///   exceeds the previous [longestStreak]; it never decreases.
  ///
  /// Throws [HabitsException] if this habit is [HabitStatus.archived] —
  /// completions may only be recorded against an [HabitStatus.active] habit.
  Habit recordCompletion(DateTime date, {required DateTime now}) {
    if (status == HabitStatus.archived) {
      throw const HabitsException(
        message: 'Cannot record a completion for an archived habit',
      );
    }

    final day = DateTime(date.year, date.month, date.day);
    final alreadyCompleted = completionLog.any((d) =>
        d.year == day.year && d.month == day.month && d.day == day.day);
    if (alreadyCompleted) {
      throw const HabitsException(
        message: 'Habit has already been completed for this day',
      );
    }

    final previous = lastCompletedAt;
    final continuesStreak = previous == null ||
        day.difference(previous).inDays <= frequency.maxGapInDays;

    final newStreak = continuesStreak ? currentStreak + 1 : 1;
    final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

    final newLog = List<DateTime>.of(completionLog)
      ..add(day)
      ..sort();

    return Habit(
      id: id,
      workspaceId: workspaceId,
      name: name,
      frequency: frequency,
      status: status,
      description: description,
      currentStreak: newStreak,
      longestStreak: newLongest,
      completionLog: newLog,
      lastCompletedAt: day,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Habit && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Habit(id: $id, name: $name, status: ${status.name}, '
      'currentStreak: $currentStreak)';
}
