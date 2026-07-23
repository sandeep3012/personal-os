import 'package:application/application.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_target_date.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateGoalInput {
  const UpdateGoalInput({
    required this.goalId,
    required this.workspaceId,
    this.name,
    this.description,
    this.targetValue,
    this.unit,
    this.targetDate,
  });

  final GoalId goalId;
  final String workspaceId;

  /// New name. `null` keeps the existing name.
  final String? name;

  /// New description. `null` keeps the existing description.
  final String? description;

  /// New target value. `null` keeps the existing target value.
  final double? targetValue;

  /// New unit label. `null` keeps the existing unit.
  final String? unit;

  /// New target date. `null` keeps the existing target date.
  final GoalTargetDate? targetDate;
}

/// Updates the mutable, non-status, non-progress fields of an existing
/// Goal.
///
/// `status` is intentionally absent from [UpdateGoalInput] — status changes
/// go through [ArchiveGoalUseCase], mirroring `UpdateTaskUseCase` rejecting
/// status as an input. Progress fields are similarly absent — those
/// change only through [CompleteGoalUseCase].
final class UpdateGoalUseCase implements AsyncUseCase<UpdateGoalInput, Goal> {
  const UpdateGoalUseCase({required IGoalRepository goalRepository})
      : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  @override
  Future<Result<Goal>> execute(UpdateGoalInput input) async {
    try {
      if (input.description != null && input.description!.length > 1000) {
        throw const GoalsException(
          message: 'Goal description must not exceed 1000 characters',
        );
      }

      final findResult = await _goalRepository.findById(
        input.goalId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) {
        return Result.failure(findResult.exceptionOrNull!);
      }

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(
          GoalsException(message: 'Goal ${input.goalId} not found'),
        );
      }

      final updated = existing.copyWith(
        name: input.name,
        description: input.description,
        targetValue: input.targetValue,
        unit: input.unit,
        targetDate: input.targetDate,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _goalRepository.save(updated);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
