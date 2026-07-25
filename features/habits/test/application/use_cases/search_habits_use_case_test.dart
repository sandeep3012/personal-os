import 'package:feature_habits/src/application/use_cases/search_habits_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_query.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_habit_repository.dart';

const _ws = 'ws-1';

Habit _habit(String id, String name, HabitStatus status) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    id: HabitId(id),
    workspaceId: _ws,
    name: name,
    frequency: HabitFrequency.daily,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeHabitRepository repo;
  late SearchHabitsUseCase useCase;

  setUp(() {
    repo = FakeHabitRepository()
      ..seed([
        _habit('t1', 'Drink water', HabitStatus.active),
        _habit('t2', 'Read a book', HabitStatus.archived),
        _habit('t3', 'Drink less coffee', HabitStatus.active),
      ]);
    useCase = SearchHabitsUseCase(habitRepository: repo);
  });

  group('SearchHabitsUseCase', () {
    test('filters by status', () async {
      final result = await useCase.execute(
        const HabitQuery(workspaceId: _ws, status: HabitStatus.active),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 2);
    });

    test('filters by name (case-insensitive contains)', () async {
      final result = await useCase.execute(
        const HabitQuery(workspaceId: _ws, nameContains: 'drink'),
      );

      expect(result.valueOrNull!.items, hasLength(2));
    });

    test('paginates results', () async {
      final result = await useCase.execute(
        const HabitQuery(workspaceId: _ws, pageSize: 2, pageIndex: 0),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 3);
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });
  });
}
