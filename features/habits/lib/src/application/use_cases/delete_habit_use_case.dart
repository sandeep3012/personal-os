import 'package:application/application.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteHabitInput {
  const DeleteHabitInput({
    required this.habitId,
    required this.workspaceId,
  });

  final HabitId habitId;
  final String workspaceId;
}

/// Soft-deletes a Habit (DOC-032 §10 Business Rule 6).
///
/// No precondition beyond existence — unlike Finance's
/// `DeleteAccountUseCase` (which checks for active transactions before
/// allowing deletion), nothing about a Habit's own fields creates a
/// cross-entity precondition (DOC-032 §4/§8: Habit is a standalone aggregate,
/// no domain services needed).
final class DeleteHabitUseCase implements AsyncUseCase<DeleteHabitInput, void> {
  const DeleteHabitUseCase({required IHabitRepository habitRepository})
      : _habitRepository = habitRepository;

  final IHabitRepository _habitRepository;

  @override
  Future<Result<void>> execute(DeleteHabitInput input) async {
    try {
      final deleteResult = await _habitRepository.softDelete(
        input.habitId,
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
