import 'package:application/application.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:platform_core/platform_core.dart';

final class CompleteHabitInput {
  const CompleteHabitInput({
    required this.habitId,
    required this.workspaceId,
    this.completedOn,
  });

  final HabitId habitId;
  final String workspaceId;

  /// The calendar day being logged as completed. Defaults to "today" at the
  /// call site (see [CompleteHabitUseCase.execute]) if left `null`.
  final DateTime? completedOn;
}

/// Records a completion ("log completion") for a Habit and advances its
/// streak counters.
///
/// Orchestration only — the streak-continuation math, duplicate-same-day
/// rejection, and the precondition that the habit not be archived all live
/// on [Habit.recordCompletion], not here. Mirrors `CompleteTaskUseCase`'s
/// shape (find, mutate via a domain method, save) even though the
/// underlying domain operation differs (transition vs. completion log).
final class CompleteHabitUseCase
    implements AsyncUseCase<CompleteHabitInput, Habit> {
  const CompleteHabitUseCase({required IHabitRepository habitRepository})
      : _habitRepository = habitRepository;

  final IHabitRepository _habitRepository;

  @override
  Future<Result<Habit>> execute(CompleteHabitInput input) async {
    try {
      final findResult = await _habitRepository.findById(
        input.habitId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) return Result.failure(findResult.exceptionOrNull!);

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(
          HabitsException(message: 'Habit ${input.habitId} not found'),
        );
      }

      final now = DateTime.now();
      final completed = existing.recordCompletion(
        input.completedOn ?? now,
        now: now,
      );

      final saveResult = await _habitRepository.save(completed);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(completed);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
