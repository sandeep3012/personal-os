import 'package:application/application.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetHabitInput {
  const GetHabitInput({required this.habitId, required this.workspaceId});

  final HabitId habitId;
  final String workspaceId;
}

/// Returns a single Habit by id. Mirrors `GetAccountByIdUseCase`.
final class GetHabitUseCase implements AsyncUseCase<GetHabitInput, Habit> {
  const GetHabitUseCase({required IHabitRepository habitRepository})
      : _habitRepository = habitRepository;

  final IHabitRepository _habitRepository;

  @override
  Future<Result<Habit>> execute(GetHabitInput input) async {
    try {
      final result = await _habitRepository.findById(
        input.habitId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final habit = result.valueOrNull;
      if (habit == null) {
        return Result.failure(
          HabitsException(message: 'Habit ${input.habitId} not found'),
        );
      }

      return Result.success(habit);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
