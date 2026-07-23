import 'package:feature_habits/src/application/use_cases/delete_habit_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

void main() {
  group('DeleteHabitUseCase', () {
    test('soft-deletes an existing habit', () async {
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
      final useCase = DeleteHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const DeleteHabitInput(habitId: HabitId('habit-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.store, isEmpty);
    });

    test('is idempotent — deleting a nonexistent habit still succeeds',
        () async {
      final repo = FakeHabitRepository();
      final useCase = DeleteHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const DeleteHabitInput(habitId: HabitId('missing'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
