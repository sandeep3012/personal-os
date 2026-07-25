import 'package:feature_habits/src/application/use_cases/get_habits_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

Habit _habit(String id, HabitStatus status) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    id: HabitId(id),
    workspaceId: _ws,
    name: 'Habit $id',
    frequency: HabitFrequency.daily,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GetHabitsUseCase', () {
    test('returns an empty list when no habits exist', () async {
      final repo = FakeHabitRepository();
      final useCase = GetHabitsUseCase(habitRepository: repo);

      final result = await useCase.execute(const GetHabitsInput(workspaceId: _ws));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all habits regardless of status, including archived',
        () async {
      final repo = FakeHabitRepository()
        ..seed([
          _habit('t1', HabitStatus.active),
          _habit('t2', HabitStatus.active),
          _habit('t3', HabitStatus.archived),
        ]);
      final useCase = GetHabitsUseCase(habitRepository: repo);

      final result = await useCase.execute(const GetHabitsInput(workspaceId: _ws));

      expect(result.valueOrNull, hasLength(3));
    });
  });
}
