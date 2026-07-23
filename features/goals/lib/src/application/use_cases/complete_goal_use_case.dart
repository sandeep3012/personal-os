import 'package:application/application.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:platform_core/platform_core.dart';

final class CompleteGoalInput {
  const CompleteGoalInput({
    required this.goalId,
    required this.workspaceId,
    required this.progressDelta,
  });

  final GoalId goalId;
  final String workspaceId;

  /// The amount of progress to add toward the goal's target.
  final double progressDelta;
}

/// Records progress against a Goal's target.
///
/// Orchestration only — the progress-accumulation math and the
/// precondition that the goal be active both live on [Goal.recordProgress],
/// not here. Mirrors `CompleteHabitUseCase`'s shape (find, mutate via a
/// domain method, save).
final class CompleteGoalUseCase
    implements AsyncUseCase<CompleteGoalInput, Goal> {
  const CompleteGoalUseCase({required IGoalRepository goalRepository})
      : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  @override
  Future<Result<Goal>> execute(CompleteGoalInput input) async {
    try {
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

      final now = DateTime.now();
      final updated = existing.recordProgress(input.progressDelta, now: now);

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
