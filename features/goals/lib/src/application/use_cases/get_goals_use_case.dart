import 'package:application/application.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetGoalsInput {
  const GetGoalsInput({required this.workspaceId});

  final String workspaceId;
}

/// Returns all non-deleted goals in the workspace, regardless of status
/// (DOC-032 §12) — filtering by status is [SearchGoalsUseCase]'s job.
/// Mirrors `GetAccountsUseCase` in shape (though `GetAccountsUseCase`
/// additionally filters to active accounts — Goal has no equivalent
/// `isActive` flag to filter by; `archived` is a status value, not a hidden
/// flag, so it is not excluded here).
final class GetGoalsUseCase implements AsyncUseCase<GetGoalsInput, List<Goal>> {
  const GetGoalsUseCase({required IGoalRepository goalRepository})
      : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  @override
  Future<Result<List<Goal>>> execute(GetGoalsInput input) async {
    try {
      final result =
          await _goalRepository.findAll(workspaceId: input.workspaceId);
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return Result.success(result.valueOrNull!);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
