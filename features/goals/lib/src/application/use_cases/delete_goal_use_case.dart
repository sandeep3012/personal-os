import 'package:application/application.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteGoalInput {
  const DeleteGoalInput({
    required this.goalId,
    required this.workspaceId,
  });

  final GoalId goalId;
  final String workspaceId;
}

/// Soft-deletes a Goal (DOC-032 §10 Business Rule 6).
///
/// No precondition beyond existence — unlike Finance's
/// `DeleteAccountUseCase` (which checks for active transactions before
/// allowing deletion), nothing about a Goal's own fields creates a
/// cross-entity precondition (DOC-032 §4/§8: Goal is a standalone aggregate,
/// no domain services needed).
final class DeleteGoalUseCase implements AsyncUseCase<DeleteGoalInput, void> {
  const DeleteGoalUseCase({required IGoalRepository goalRepository})
      : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  @override
  Future<Result<void>> execute(DeleteGoalInput input) async {
    try {
      final deleteResult = await _goalRepository.softDelete(
        input.goalId,
        workspaceId: input.workspaceId,
      );
      if (deleteResult.isFailure) {
        return Result.failure(deleteResult.exceptionOrNull!);
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
