import 'package:application/application.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:platform_core/platform_core.dart';

final class CreateHabitInput {
  const CreateHabitInput({
    required this.workspaceId,
    required this.name,
    required this.frequency,
    this.description,
  });

  final String workspaceId;
  final String name;
  final HabitFrequency frequency;
  final String? description;
}

/// Creates a new Habit and persists it via [IHabitRepository].
///
/// New habits always start at [HabitStatus.active] with a zeroed streak and
/// empty completion log — mirrors `CreateTaskUseCase` in shape.
///
/// Validates [CreateHabitInput.description] (max 1000 characters) at this
/// layer — the [Habit] entity constructor enforces the name invariants
/// itself.
final class CreateHabitUseCase implements AsyncUseCase<CreateHabitInput, Habit> {
  CreateHabitUseCase({
    required IHabitRepository habitRepository,
    required IdGenerator idGenerator,
  })  : _habitRepository = habitRepository,
        _idGenerator = idGenerator;

  final IHabitRepository _habitRepository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<Habit>> execute(CreateHabitInput input) async {
    try {
      if (input.description != null && input.description!.length > 1000) {
        throw const HabitsException(
          message: 'Habit description must not exceed 1000 characters',
        );
      }

      final now = DateTime.now();
      final habit = Habit(
        id: HabitId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        name: input.name,
        frequency: input.frequency,
        status: HabitStatus.active,
        description: input.description,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _habitRepository.save(habit);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(habit);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
