import 'package:application/application.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:platform_core/platform_core.dart';

final class ArchiveGoalInput {
  const ArchiveGoalInput({
    required this.goalId,
    required this.workspaceId,
  });

  final GoalId goalId;
  final String workspaceId;
}

/// Transitions a Goal to [GoalStatus.archived] from any non-archived status
/// (DOC-032 §11).
///
/// Rejects (via [Goal.transitionTo]) if the goal is already archived —
/// mirrors Finance's pattern of failing loudly on an invalid precondition
/// rather than silently accepting a no-op.
final class ArchiveGoalUseCase implements AsyncUseCase<ArchiveGoalInput, Goal> {
  const ArchiveGoalUseCase({required IGoalRepository goalRepository})
      : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  @override
  Future<Result<Goal>> execute(ArchiveGoalInput input) async {
    try {
      final findResult = await _goalRepository.findById(
        input.goalId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) return Result.failure(findResult.exceptionOrNull!);

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(
          GoalsException(message: 'Goal ${input.goalId} not found'),
        );
      }

      final archived = existing.transitionTo(
        GoalStatus.archived,
        now: DateTime.now(),
      );

      final saveResult = await _goalRepository.save(archived);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(archived);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
