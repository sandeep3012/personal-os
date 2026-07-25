import 'package:application/application.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateHabitInput {
  const UpdateHabitInput({
    required this.habitId,
    required this.workspaceId,
    this.name,
    this.description,
    this.frequency,
  });

  final HabitId habitId;
  final String workspaceId;

  /// New name. `null` keeps the existing name.
  final String? name;

  /// New description. `null` keeps the existing description.
  final String? description;

  /// New frequency. `null` keeps the existing frequency.
  final HabitFrequency? frequency;
}

/// Updates the mutable, non-status, non-streak fields of an existing Habit.
///
/// `status` is intentionally absent from [UpdateHabitInput] — status changes
/// go through [ArchiveHabitUseCase], mirroring `UpdateTaskUseCase` rejecting
/// status as an input. Streak/completion fields are similarly absent — those
/// change only through [CompleteHabitUseCase].
final class UpdateHabitUseCase implements AsyncUseCase<UpdateHabitInput, Habit> {
  const UpdateHabitUseCase({required IHabitRepository habitRepository})
      : _habitRepository = habitRepository;

  final IHabitRepository _habitRepository;

  @override
  Future<Result<Habit>> execute(UpdateHabitInput input) async {
    try {
      if (input.description != null && input.description!.length > 1000) {
        throw const HabitsException(
          message: 'Habit description must not exceed 1000 characters',
        );
      }

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

      final updated = existing.copyWith(
        name: input.name,
        description: input.description,
        frequency: input.frequency,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _habitRepository.save(updated);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
