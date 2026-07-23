import 'package:application/application.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetHabitsInput {
  const GetHabitsInput({required this.workspaceId});

  final String workspaceId;
}

/// Returns all non-deleted habits in the workspace, regardless of status
/// (DOC-032 §12) — filtering by status is [SearchHabitsUseCase]'s job.
/// Mirrors `GetAccountsUseCase` in shape (though `GetAccountsUseCase`
/// additionally filters to active accounts — Habit has no equivalent
/// `isActive` flag to filter by; `archived` is a status value, not a hidden
/// flag, so it is not excluded here).
final class GetHabitsUseCase implements AsyncUseCase<GetHabitsInput, List<Habit>> {
  const GetHabitsUseCase({required IHabitRepository habitRepository})
      : _habitRepository = habitRepository;

  final IHabitRepository _habitRepository;

  @override
  Future<Result<List<Habit>>> execute(GetHabitsInput input) async {
    try {
      final result =
          await _habitRepository.findAll(workspaceId: input.workspaceId);
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return Result.success(result.valueOrNull!);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
