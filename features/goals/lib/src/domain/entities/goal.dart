import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:feature_goals/src/domain/value_objects/goal_target_date.dart';

/// A Goal aggregate root — a single, standalone measurable outcome a user is
/// pursuing (mirrors DOC-032 §4's Task/Habit aggregate shape). There is no
/// owning Project/List/Board entity; grouping, if ever introduced, happens
/// through the platform Entity Linking Service, not through a field on this
/// entity.
///
/// Business invariants enforced here:
/// - [name] must not be empty and must not exceed 200 characters (mirrors
///   Task/Habit's title invariant).
/// - [targetValue] must be strictly positive.
/// - [currentProgress] must never be negative and is only ever changed by
///   [recordProgress] (no public setter).
/// - Status transitions are only permitted per the approved transition table
///   — enforced by [transitionTo], not by direct field mutation (this class
///   has no public status setter).
final class Goal {
  Goal({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.targetValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.unit,
    this.currentProgress = 0,
    this.targetDate,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const GoalsException(message: 'Goal name must not be empty');
    }
    if (name.length > 200) {
      throw const GoalsException(
        message: 'Goal name must not exceed 200 characters',
      );
    }
    if (targetValue <= 0) {
      throw const GoalsException(
        message: 'Goal targetValue must be strictly positive',
      );
    }
    if (currentProgress < 0) {
      throw const GoalsException(
        message: 'Goal currentProgress must not be negative',
      );
    }
  }

  final GoalId id;
  final String workspaceId;
  final String name;

  /// The measurable value that counts as achieving this goal (e.g. `10` for
  /// "run 10 races", `5000` for "save $5000"). Always strictly positive.
  final double targetValue;

  /// The current measured progress toward [targetValue]. Never negative,
  /// never mutated directly — only via [recordProgress].
  final double currentProgress;

  /// Optional free-text unit label for [targetValue]/[currentProgress]
  /// (e.g. `"km"`, `"books"`, `"USD"`).
  final String? unit;

  final GoalStatus status;

  /// Optional target completion date. Absence means the goal is open-ended.
  final GoalTargetDate? targetDate;

  /// Optional free text. Max 1000 characters — enforced at the use-case
  /// validation layer, mirroring how Task validates `description` there
  /// rather than in the entity constructor.
  final String? description;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Fraction of [targetValue] reached so far, clamped to `[0, 1]`.
  double get progressRatio =>
      (currentProgress / targetValue).clamp(0, 1).toDouble();

  /// Returns a copy of this goal with the supplied fields replaced.
  ///
  /// Does not change [status] — use [transitionTo] for status changes. Does
  /// not change [currentProgress] — use [recordProgress]. Mirrors
  /// `Task.copyWith` rejecting status as an updatable field.
  Goal copyWith({
    String? name,
    String? description,
    double? targetValue,
    String? unit,
    GoalTargetDate? targetDate,
    DateTime? updatedAt,
  }) =>
      Goal(
        id: id,
        workspaceId: workspaceId,
        name: name ?? this.name,
        targetValue: targetValue ?? this.targetValue,
        unit: unit ?? this.unit,
        status: status,
        description: description ?? this.description,
        currentProgress: currentProgress,
        targetDate: targetDate ?? this.targetDate,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy of this goal transitioned to [next].
  ///
  /// Throws [GoalsException] if [next] is not reachable from [status] per
  /// the approved transition table:
  ///
  /// ```
  /// active    -> completed | archived
  /// completed -> archived
  /// archived  -> (none — terminal)
  /// ```
  Goal transitionTo(GoalStatus next, {required DateTime now}) {
    if (!status.canTransitionTo(next)) {
      throw GoalsException(
        message:
            'Cannot transition Goal from ${status.name} to ${next.name}',
      );
    }
    return Goal(
      id: id,
      workspaceId: workspaceId,
      name: name,
      targetValue: targetValue,
      unit: unit,
      status: next,
      description: description,
      currentProgress: currentProgress,
      targetDate: targetDate,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Returns a copy of this goal with [delta] added to [currentProgress]
  /// (the core Goals business rule).
  ///
  /// - Throws [GoalsException] if this goal is not [GoalStatus.active] —
  ///   progress may only be recorded against an active goal.
  /// - Throws [GoalsException] if [delta] would drive [currentProgress]
  ///   negative.
  /// - Does **not** automatically transition [status] to
  ///   [GoalStatus.completed] when [currentProgress] reaches [targetValue] —
  ///   that is an explicit user/use-case decision via [transitionTo],
  ///   mirroring how Habit does not auto-archive on streak milestones.
  Goal recordProgress(double delta, {required DateTime now}) {
    if (status != GoalStatus.active) {
      throw const GoalsException(
        message: 'Cannot record progress for a goal that is not active',
      );
    }
    final newProgress = currentProgress + delta;
    if (newProgress < 0) {
      throw const GoalsException(
        message: 'Goal currentProgress must not be negative',
      );
    }
    return Goal(
      id: id,
      workspaceId: workspaceId,
      name: name,
      targetValue: targetValue,
      unit: unit,
      status: status,
      description: description,
      currentProgress: newProgress,
      targetDate: targetDate,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Goal && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Goal(id: $id, name: $name, status: ${status.name}, '
      'currentProgress: $currentProgress/$targetValue)';
}
