import 'package:feature_habits/src/application/use_cases/complete_habit_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

Habit _existing({
  HabitStatus status = HabitStatus.active,
  int currentStreak = 0,
  int longestStreak = 0,
  List<DateTime>? completionLog,
  DateTime? lastCompletedAt,
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
    completionLog: completionLog,
    lastCompletedAt: lastCompletedAt,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CompleteHabitUseCase', () {
    test('records a first completion and starts a streak of 1', () async {
      final repo = FakeHabitRepository()..seed([_existing()]);
      final useCase = CompleteHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const CompleteHabitInput(habitId: HabitId('habit-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.currentStreak, 1);
      expect(result.valueOrNull!.lastCompletedAt, isNotNull);
    });

    test('uses the supplied completedOn date instead of today when given', () async {
      final repo = FakeHabitRepository()..seed([_existing()]);
      final useCase = CompleteHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        CompleteHabitInput(
          habitId: const HabitId('habit-1'),
          workspaceId: _ws,
          completedOn: DateTime(2026, 5, 1),
        ),
      );

      expect(result.valueOrNull!.lastCompletedAt, DateTime(2026, 5, 1));
    });

    test('rejects completing an already-archived habit', () async {
      final repo = FakeHabitRepository()..seed([_existing(status: HabitStatus.archived)]);
      final useCase = CompleteHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const CompleteHabitInput(habitId: HabitId('habit-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });

    test('rejects completing the same calendar day twice', () async {
      final today = DateTime.now();
      final day = DateTime(today.year, today.month, today.day);
      final repo = FakeHabitRepository()
        ..seed([
          _existing(currentStreak: 1, longestStreak: 1, completionLog: [day], lastCompletedAt: day),
        ]);
      final useCase = CompleteHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const CompleteHabitInput(habitId: HabitId('habit-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });

    test('fails when the habit does not exist', () async {
      final repo = FakeHabitRepository();
      final useCase = CompleteHabitUseCase(habitRepository: repo);

      final result = await useCase.execute(
        const CompleteHabitInput(habitId: HabitId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });
  });
}
