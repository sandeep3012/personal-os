import 'package:application/application.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:platform_core/platform_core.dart';

final class ArchiveHabitInput {
  const ArchiveHabitInput({
    required this.habitId,
    required this.workspaceId,
  });

  final HabitId habitId;
  final String workspaceId;
}

/// Transitions a Habit to [HabitStatus.archived] from any non-archived status
/// (DOC-032 §11).
///
/// Rejects (via [Habit.transitionTo]) if the habit is already archived —
/// mirrors Finance's pattern of failing loudly on an invalid precondition
/// rather than silently accepting a no-op.
final class ArchiveHabitUseCase implements AsyncUseCase<ArchiveHabitInput, Habit> {
  const ArchiveHabitUseCase({required IHabitRepository habitRepository})
      : _habitRepository = habitRepository;

  final IHabitRepository _habitRepository;

  @override
  Future<Result<Habit>> execute(ArchiveHabitInput input) async {
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

      final archived = existing.transitionTo(
        HabitStatus.archived,
        now: DateTime.now(),
      );

      final saveResult = await _habitRepository.save(archived);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(archived);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
