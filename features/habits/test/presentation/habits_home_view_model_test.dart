import 'package:application/application.dart';
import 'package:feature_habits/src/application/use_cases/get_habits_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:feature_habits/src/presentation/viewmodels/habits_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

Habit _habit(
  String id, {
  HabitStatus status = HabitStatus.active,
  DateTime? lastCompletedAt,
}) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    id: HabitId(id),
    workspaceId: _ws,
    name: 'Habit $id',
    frequency: HabitFrequency.daily,
    status: status,
    lastCompletedAt: lastCompletedAt,
    createdAt: now,
    updatedAt: now,
  );
}

final class _Harness {
  _Harness() : repo = FakeHabitRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = HabitsHomeViewModel(
      getHabitsUseCase: GetHabitsUseCase(habitRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeHabitRepository repo;
  late final WorkspaceContext workspaceContext;
  late final HabitsHomeViewModel viewModel;
}

void main() {
  group('HabitsHomeViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('activeCount counts only active habits', () async {
      final harness = _Harness()
        ..repo.seed([
          _habit('t1', status: HabitStatus.active),
          _habit('t2', status: HabitStatus.active),
          _habit('t3', status: HabitStatus.archived),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.activeCount, 2);
    });

    test('completedTodayCount counts only habits completed on the current date',
        () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final harness = _Harness()
        ..repo.seed([
          _habit('t1', lastCompletedAt: now),
          _habit('t2', lastCompletedAt: now),
          _habit('t3', lastCompletedAt: yesterday),
          _habit('t4'),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.completedTodayCount, 2);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });
}
