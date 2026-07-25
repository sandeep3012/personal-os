import 'package:feature_habits/src/application/use_cases/get_habit_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

void main() {
  group('GetHabitUseCase', () {
    test('returns the habit when it exists', () async {
      final now = DateTime(2026, 1, 1);
      final habit = Habit(
        id: const HabitId('habit-1'),
        workspaceId: _ws,
        name: 'Habit',
    frequency: HabitFrequency.daily,
        status: HabitStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final repo = FakeHabitRepository()..seed([habit]);
      final useCase = GetHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const GetHabitInput(habitId: HabitId('habit-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'Habit');
    });

    test('fails when the habit does not exist', () async {
      final repo = FakeHabitRepository();
      final useCase = GetHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const GetHabitInput(habitId: HabitId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });
  });
}
