import 'package:feature_habits/src/application/use_cases/archive_habit_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

Habit _existing(
  HabitStatus status, {
  int currentStreak = 0,
  int longestStreak = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    id: const HabitId('habit-1'),
    workspaceId: _ws,
    name: 'Habit',
    frequency: HabitFrequency.daily,
    status: status,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ArchiveHabitUseCase', () {
    test('archives an active habit', () async {
      final repo = FakeHabitRepository()..seed([_existing(HabitStatus.active)]);
      final useCase = ArchiveHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const ArchiveHabitInput(habitId: HabitId('habit-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, HabitStatus.archived);
    });

    test('archiving retains the streak counters', () async {
      final repo = FakeHabitRepository()
        ..seed([_existing(HabitStatus.active, currentStreak: 4, longestStreak: 6)]);
      final useCase = ArchiveHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const ArchiveHabitInput(habitId: HabitId('habit-1'), workspaceId: _ws),
      );

      expect(result.valueOrNull!.currentStreak, 4);
      expect(result.valueOrNull!.longestStreak, 6);
    });

    test('rejects archiving an already-archived habit', () async {
      final repo = FakeHabitRepository()..seed([_existing(HabitStatus.archived)]);
      final useCase = ArchiveHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const ArchiveHabitInput(habitId: HabitId('habit-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });

    test('fails when the habit does not exist', () async {
      final repo = FakeHabitRepository();
      final useCase = ArchiveHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const ArchiveHabitInput(habitId: HabitId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
