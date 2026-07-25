import 'package:application/application.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetGoalInput {
  const GetGoalInput({required this.goalId, required this.workspaceId});

  final GoalId goalId;
  final String workspaceId;
}

/// Returns a single Goal by id. Mirrors `GetAccountByIdUseCase`.
final class GetGoalUseCase implements AsyncUseCase<GetGoalInput, Goal> {
  const GetGoalUseCase({required IGoalRepository goalRepository})
      : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  @override
  Future<Result<Goal>> execute(GetGoalInput input) async {
    try {
      final result = await _goalRepository.findById(
        input.goalId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final goal = result.valueOrNull;
      if (goal == null) {
        return Result.failure(
          GoalsException(message: 'Goal ${input.goalId} not found'),
        );
      }

      return Result.success(goal);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
