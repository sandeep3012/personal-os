import 'package:feature_goals/src/application/use_cases/search_goals_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_query.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_goal_repository.dart';

const _ws = 'ws-1';

Goal _goal(String id, String name, GoalStatus status) {
  final now = DateTime(2026, 1, 1);
  return Goal(
    id: GoalId(id),
    workspaceId: _ws,
    name: name,
    targetValue: 10,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeGoalRepository repo;
  late SearchGoalsUseCase useCase;

  setUp(() {
    repo = FakeGoalRepository()
      ..seed([
        _goal('t1', 'Drink water', GoalStatus.active),
        _goal('t2', 'Read a book', GoalStatus.archived),
        _goal('t3', 'Drink less coffee', GoalStatus.active),
      ]);
    useCase = SearchGoalsUseCase(goalRepository: repo);
  });

  group('SearchGoalsUseCase', () {
    test('filters by status', () async {
      final result = await useCase.execute(
        const GoalQuery(workspaceId: _ws, status: GoalStatus.active),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 2);
    });

    test('filters by name (case-insensitive contains)', () async {
      final result = await useCase.execute(
        const GoalQuery(workspaceId: _ws, nameContains: 'drink'),
      );

      expect(result.valueOrNull!.items, hasLength(2));
    });

    test('paginates results', () async {
      final result = await useCase.execute(
        const GoalQuery(workspaceId: _ws, pageSize: 2, pageIndex: 0),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 3);
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });
  });
}
