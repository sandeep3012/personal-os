import 'package:feature_habits/src/application/use_cases/create_habit_use_case.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../../helpers/fake_habit_repository.dart';

final class _FixedIdGenerator implements IdGenerator {
  int _i = 0;
  @override
  String generate() => 'habit-${++_i}';
}

void main() {
  late FakeHabitRepository repo;
  late CreateHabitUseCase useCase;

  setUp(() {
    repo = FakeHabitRepository();
    useCase = CreateHabitUseCase(
      habitRepository: repo,
      idGenerator: _FixedIdGenerator(),
    );
  });

  group('CreateHabitUseCase', () {
    test('creates and persists a habit starting active with a zero streak', () async {
      final result = await useCase.execute(
        const CreateHabitInput(
          workspaceId: 'ws-1',
          name: 'Drink water',
          frequency: HabitFrequency.daily,
        ),
      );

      expect(result.isSuccess, isTrue);
      final habit = result.valueOrNull!;
      expect(habit.name, 'Drink water');
      expect(habit.status, HabitStatus.active);
      expect(habit.currentStreak, 0);
      expect(habit.completionLog, isEmpty);
      expect(repo.store, contains(habit));
    });

    test('returns generated id for the new habit', () async {
      final result = await useCase.execute(
        const CreateHabitInput(
          workspaceId: 'ws-1',
          name: 'Habit',
          frequency: HabitFrequency.daily,
        ),
      );

      expect(result.valueOrNull!.id.value, 'habit-1');
    });

    test('accepts an optional description and a frequency', () async {
      final result = await useCase.execute(
        const CreateHabitInput(
          workspaceId: 'ws-1',
          name: 'Habit',
          frequency: HabitFrequency.weekly,
          description: 'Details',
        ),
      );

      expect(result.valueOrNull!.description, 'Details');
      expect(result.valueOrNull!.frequency, HabitFrequency.weekly);
    });

    test('rejects a description longer than 1000 characters', () async {
      final result = await useCase.execute(
        CreateHabitInput(
          workspaceId: 'ws-1',
          name: 'Habit',
          frequency: HabitFrequency.daily,
          description: 'a' * 1001,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });

    test('rejects an empty name (entity invariant)', () async {
      final result = await useCase.execute(
        const CreateHabitInput(
          workspaceId: 'ws-1',
          name: '',
          frequency: HabitFrequency.daily,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });
  });
}
