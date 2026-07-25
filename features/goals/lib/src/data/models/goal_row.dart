import 'package:feature_goals/src/data/schema/goals_schema.dart';

/// A single, unmapped row from the `goals` table.
///
/// [GoalRow] is a persistence-layer data shape only — it has no business
/// methods, no validation, and no relationship to the domain `Goal` entity.
/// Mapping between [GoalRow] and `Goal` is a repository-layer concern, not
/// a DAO concern. Mirrors Finance's `AccountRow`/`TransactionRow` and Habits'
/// `HabitRow`.
final class GoalRow {
  const GoalRow({
    required this.goalId,
    required this.workspaceId,
    required this.name,
    required this.targetValue,
    required this.currentProgress,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.unit,
    this.targetDate,
    this.deletedAt,
  });

  final String goalId;
  final String workspaceId;
  final String name;
  final double targetValue;
  final double currentProgress;
  final String status;
  final String? description;
  final String? unit;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Builds a [GoalRow] from a raw SQL result row.
  factory GoalRow.fromMap(Map<String, Object?> map) {
    final targetDateValue = map[GoalsSchema.goalTargetDate] as String?;
    final deletedAtValue = map[GoalsSchema.goalDeletedAt] as String?;
    return GoalRow(
      goalId: map[GoalsSchema.goalId]! as String,
      workspaceId: map[GoalsSchema.goalWorkspaceId]! as String,
      name: map[GoalsSchema.goalName]! as String,
      targetValue: (map[GoalsSchema.goalTargetValue]! as num).toDouble(),
      currentProgress:
          (map[GoalsSchema.goalCurrentProgress]! as num).toDouble(),
      status: map[GoalsSchema.goalStatus]! as String,
      description: map[GoalsSchema.goalDescription] as String?,
      unit: map[GoalsSchema.goalUnit] as String?,
      targetDate: targetDateValue == null
          ? null
          : DateTime.parse(targetDateValue),
      createdAt: DateTime.parse(map[GoalsSchema.goalCreatedAt]! as String),
      updatedAt: DateTime.parse(map[GoalsSchema.goalUpdatedAt]! as String),
      deletedAt:
          deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [GoalsSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        GoalsSchema.goalId: goalId,
        GoalsSchema.goalWorkspaceId: workspaceId,
        GoalsSchema.goalName: name,
        GoalsSchema.goalTargetValue: targetValue,
        GoalsSchema.goalCurrentProgress: currentProgress,
        GoalsSchema.goalStatus: status,
        GoalsSchema.goalDescription: description,
        GoalsSchema.goalUnit: unit,
        GoalsSchema.goalTargetDate: targetDate?.toIso8601String(),
        GoalsSchema.goalCreatedAt: createdAt.toIso8601String(),
        GoalsSchema.goalUpdatedAt: updatedAt.toIso8601String(),
        GoalsSchema.goalDeletedAt: deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.goalId == goalId &&
          other.workspaceId == workspaceId &&
          other.name == name &&
          other.targetValue == targetValue &&
          other.currentProgress == currentProgress &&
          other.status == status &&
          other.description == description &&
          other.unit == unit &&
          other.targetDate == targetDate &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        goalId,
        workspaceId,
        name,
        targetValue,
        currentProgress,
        status,
        description,
        unit,
        targetDate,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'GoalRow(goalId: $goalId, name: $name)';
}
