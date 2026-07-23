import 'package:application/application.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:feature_goals/src/domain/value_objects/goal_target_date.dart';
import 'package:platform_core/platform_core.dart';

final class CreateGoalInput {
  const CreateGoalInput({
    required this.workspaceId,
    required this.name,
    required this.targetValue,
    this.unit,
    this.targetDate,
    this.description,
  });

  final String workspaceId;
  final String name;
  final double targetValue;
  final String? unit;
  final GoalTargetDate? targetDate;
  final String? description;
}

/// Creates a new Goal and persists it via [IGoalRepository].
///
/// New goals always start at [GoalStatus.active] with zero progress —
/// mirrors `CreateHabitUseCase` in shape.
///
/// Validates [CreateGoalInput.description] (max 1000 characters) at this
/// layer — the [Goal] entity constructor enforces the name/target
/// invariants itself.
final class CreateGoalUseCase implements AsyncUseCase<CreateGoalInput, Goal> {
  CreateGoalUseCase({
    required IGoalRepository goalRepository,
    required IdGenerator idGenerator,
  })  : _goalRepository = goalRepository,
        _idGenerator = idGenerator;

  final IGoalRepository _goalRepository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<Goal>> execute(CreateGoalInput input) async {
    try {
      if (input.description != null && input.description!.length > 1000) {
        throw const GoalsException(
          message: 'Goal description must not exceed 1000 characters',
        );
      }

      final now = DateTime.now();
      final goal = Goal(
        id: GoalId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        name: input.name,
        targetValue: input.targetValue,
        unit: input.unit,
        targetDate: input.targetDate,
        status: GoalStatus.active,
        description: input.description,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _goalRepository.save(goal);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(goal);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
