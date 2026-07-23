import 'package:application/application.dart';
import 'package:feature_habits/src/application/use_cases/archive_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/complete_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/create_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/delete_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/get_habits_use_case.dart';
import 'package:feature_habits/src/application/use_cases/update_habit_use_case.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:feature_habits/src/presentation/viewmodels/habits_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'habit-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeHabitRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = HabitsViewModel(
      getHabitsUseCase: GetHabitsUseCase(habitRepository: repo),
      createHabitUseCase: CreateHabitUseCase(
        habitRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateHabitUseCase: UpdateHabitUseCase(habitRepository: repo),
      completeHabitUseCase: CompleteHabitUseCase(habitRepository: repo),
      archiveHabitUseCase: ArchiveHabitUseCase(habitRepository: repo),
      deleteHabitUseCase: DeleteHabitUseCase(habitRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeHabitRepository repo;
  late final WorkspaceContext workspaceContext;
  late final HabitsViewModel viewModel;
}

void main() {
  group('HabitsViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('shows an empty list when no habits exist', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      // Should not throw — the ViewModel unsubscribed from WorkspaceContext
      // in dispose(), so this switch must not touch a disposed ChangeNotifier.
      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });

  group('HabitsViewModel.createHabit', () {
    test('creates a habit starting active with a zero streak and reloads the list',
        () async {
      final harness = _Harness();
      await harness.viewModel.load();

      final result = await harness.viewModel.createHabit(
        name: 'Buy milk',
        frequency: HabitFrequency.daily,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, HabitStatus.active);
      expect(result.valueOrNull!.currentStreak, 0);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('HabitsViewModel.updateHabit', () {
    test('updates the name and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createHabit(
        name: 'Original',
        frequency: HabitFrequency.daily,
      );

      final result = await harness.viewModel.updateHabit(
        habitId: created.valueOrNull!.id,
        name: 'Renamed',
      );

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull!.single.name, 'Renamed');
    });
  });

  group('HabitsViewModel.completeHabit', () {
    test('logs a completion, advances the streak, and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createHabit(
        name: 'Habit',
        frequency: HabitFrequency.daily,
      );

      final result = await harness.viewModel.completeHabit(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.currentStreak, 1);
    });

    test('fails when the habit is archived', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createHabit(
        name: 'Habit',
        frequency: HabitFrequency.daily,
      );
      await harness.viewModel.archiveHabit(created.valueOrNull!.id);

      final result = await harness.viewModel.completeHabit(created.valueOrNull!.id);

      expect(result.isFailure, isTrue);
    });
  });

  group('HabitsViewModel.archiveHabit', () {
    test('archives a habit and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createHabit(
        name: 'Habit',
        frequency: HabitFrequency.daily,
      );

      final result = await harness.viewModel.archiveHabit(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, HabitStatus.archived);
    });
  });

  group('HabitsViewModel.deleteHabit', () {
    test('soft-deletes a habit and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createHabit(
        name: 'Habit',
        frequency: HabitFrequency.daily,
      );
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      final result = await harness.viewModel.deleteHabit(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });
}
