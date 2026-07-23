import 'package:feature_habits/src/application/use_cases/update_habit_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

Habit _existing({HabitStatus status = HabitStatus.active}) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    id: const HabitId('habit-1'),
    workspaceId: _ws,
    name: 'Original title',
    frequency: HabitFrequency.daily,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeHabitRepository repo;
  late UpdateHabitUseCase useCase;

  setUp(() {
    repo = FakeHabitRepository()..seed([_existing()]);
    useCase = UpdateHabitUseCase(habitRepository: repo);
  });

  group('UpdateHabitUseCase', () {
    test('updates the name', () async {
      final result = await useCase.execute(
        const UpdateHabitInput(
          habitId: HabitId('habit-1'),
          workspaceId: _ws,
          name: 'Renamed',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'Renamed');
    });

    test('does not change status', () async {
      final result = await useCase.execute(
        const UpdateHabitInput(
          habitId: HabitId('habit-1'),
          workspaceId: _ws,
          name: 'Renamed',
        ),
      );

      expect(result.valueOrNull!.status, HabitStatus.active);
    });

    test('rejects a description longer than 1000 characters', () async {
      final result = await useCase.execute(
        UpdateHabitInput(
          habitId: const HabitId('habit-1'),
          workspaceId: _ws,
          description: 'a' * 1001,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });

    test('fails when the habit does not exist', () async {
      final result = await useCase.execute(
        const UpdateHabitInput(
          habitId: HabitId('missing'),
          workspaceId: _ws,
          name: 'X',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });
  });
}
