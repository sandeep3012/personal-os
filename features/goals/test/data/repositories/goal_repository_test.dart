import 'package:feature_goals/src/data/dao/goal_dao.dart';
import 'package:feature_goals/src/data/mappers/goal_mapper.dart';
import 'package:feature_goals/src/data/models/goal_row.dart';
import 'package:feature_goals/src/data/repositories/goal_repository.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/exceptions/goals_exception.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_query.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dao/fake_goal_database_executor.dart';

// Mirrors Finance's account_repository_test.dart: exercises GoalRepository
// against the real GoalDao and GoalMapper, with the fake at the
// FakeGoalDatabaseExecutor boundary.

GoalRow _row({
  String id = 'goal-1',
  String workspaceId = 'ws-1',
  String name = 'Drink water',
}) {
  final now = DateTime(2024, 1, 1);
  return GoalRow(
    goalId: id,
    workspaceId: workspaceId,
    name: name,
    targetValue: 10,
    currentProgress: 0,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

Goal _goal({String id = 'goal-1', String workspaceId = 'ws-1'}) {
  final now = DateTime(2024, 1, 1);
  return Goal(
    id: GoalId(id),
    workspaceId: workspaceId,
    name: 'Drink water',
    targetValue: 10,
    status: GoalStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeGoalDatabaseExecutor executor;
  late GoalRepository repository;

  setUp(() {
    executor = FakeGoalDatabaseExecutor();
    repository = GoalRepository(
      goalDao: GoalDao(executor),
      goalMapper: const GoalMapper(),
    );
  });

  group('GoalRepository.findById', () {
    test('returns a correctly mapped Goal when the row exists', () async {
      executor.queryResults.add([_row(id: 'goal-1', name: 'My Goal').toMap()]);

      final result =
          await repository.findById(const GoalId('goal-1'), workspaceId: 'ws-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'My Goal');
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const GoalId('missing'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure into a GoalsException', () async {
      executor.queryError = Exception('disk read error');

      final result = await repository.findById(
        const GoalId('goal-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
      expect(result.exceptionOrNull!.message, contains('disk read error'));
    });

    test('passes through a GoalsException raised by the mapper unchanged',
        () async {
      final corruptRow = _row(id: 'goal-1').toMap();
      corruptRow['status'] = 'not_a_real_status';
      executor.queryResults.add([corruptRow]);

      final result = await repository.findById(
        const GoalId('goal-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull!.message, contains('Unrecognized status'));
    });
  });

  group('GoalRepository.findAll', () {
    test('maps all rows', () async {
      executor.queryResults.add([
        _row(id: 'goal-a', name: 'A').toMap(),
        _row(id: 'goal-b', name: 'B').toMap(),
      ]);

      final result = await repository.findAll(workspaceId: 'ws-1');

      expect(result.valueOrNull!.map((h) => h.name), ['A', 'B']);
    });

    test('returns an empty list, not a failure, when no goals exist', () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });

  group('GoalRepository.findByStatus', () {
    test('scopes the DAO call by status', () async {
      executor.queryResults.add([_row(id: 'goal-1').toMap()]);

      final result = await repository.findByStatus(
        GoalStatus.active,
        workspaceId: 'ws-1',
      );

      expect(executor.executedQueryArgs.single, ['ws-1', 'active']);
      expect(result.valueOrNull, hasLength(1));
    });
  });

  group('GoalRepository.search', () {
    test('maps the DAO query result into a GoalPage', () async {
      executor.queryResults.add([
        {'total': 1},
      ]);
      executor.queryResults.add([_row(id: 'goal-1').toMap()]);

      final result = await repository.search(
        const GoalQuery(workspaceId: 'ws-1'),
      );

      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items, hasLength(1));
    });
  });

  group('GoalRepository.save', () {
    test('inserts a new goal when it does not already exist', () async {
      final result = await repository.save(_goal(id: 'goal-new'));

      expect(result.isSuccess, isTrue);
      final insertSql =
          executor.executedStatements.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO goals'));
    });

    test('updates an existing goal instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      final result = await repository.save(_goal(id: 'goal-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql =
          executor.executedStatements.firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE goals SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('write failed');
      final result = await repository.save(_goal());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });
  });

  group('GoalRepository.softDelete', () {
    test('delegates directly to GoalDao.softDelete', () async {
      final result = await repository.softDelete(
        const GoalId('goal-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const GoalId('goal-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<GoalsException>());
    });
  });
}
