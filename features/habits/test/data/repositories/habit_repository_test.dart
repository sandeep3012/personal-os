import 'package:feature_habits/src/data/dao/habit_dao.dart';
import 'package:feature_habits/src/data/mappers/habit_mapper.dart';
import 'package:feature_habits/src/data/models/habit_row.dart';
import 'package:feature_habits/src/data/repositories/habit_repository.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/exceptions/habits_exception.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_query.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dao/fake_habit_database_executor.dart';

// Mirrors Finance's account_repository_test.dart: exercises HabitRepository
// against the real HabitDao and HabitMapper, with the fake at the
// FakeHabitDatabaseExecutor boundary.

HabitRow _row({
  String id = 'habit-1',
  String workspaceId = 'ws-1',
  String name = 'Drink water',
}) {
  final now = DateTime(2024, 1, 1);
  return HabitRow(
    habitId: id,
    workspaceId: workspaceId,
    name: name,
    frequency: 'daily',
    status: 'active',
    currentStreak: 0,
    longestStreak: 0,
    completionLog: const [],
    createdAt: now,
    updatedAt: now,
  );
}

Habit _habit({String id = 'habit-1', String workspaceId = 'ws-1'}) {
  final now = DateTime(2024, 1, 1);
  return Habit(
    id: HabitId(id),
    workspaceId: workspaceId,
    name: 'Drink water',
    frequency: HabitFrequency.daily,
    status: HabitStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeHabitDatabaseExecutor executor;
  late HabitRepository repository;

  setUp(() {
    executor = FakeHabitDatabaseExecutor();
    repository = HabitRepository(
      habitDao: HabitDao(executor),
      habitMapper: const HabitMapper(),
    );
  });

  group('HabitRepository.findById', () {
    test('returns a correctly mapped Habit when the row exists', () async {
      executor.queryResults.add([_row(id: 'habit-1', name: 'My Habit').toMap()]);

      final result =
          await repository.findById(const HabitId('habit-1'), workspaceId: 'ws-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'My Habit');
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const HabitId('missing'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure into a HabitsException', () async {
      executor.queryError = Exception('disk read error');

      final result = await repository.findById(
        const HabitId('habit-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
      expect(result.exceptionOrNull!.message, contains('disk read error'));
    });

    test('passes through a HabitsException raised by the mapper unchanged',
        () async {
      final corruptRow = _row(id: 'habit-1').toMap();
      corruptRow['status'] = 'not_a_real_status';
      executor.queryResults.add([corruptRow]);

      final result = await repository.findById(
        const HabitId('habit-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull!.message, contains('Unrecognized status'));
    });
  });

  group('HabitRepository.findAll', () {
    test('maps all rows', () async {
      executor.queryResults.add([
        _row(id: 'habit-a', name: 'A').toMap(),
        _row(id: 'habit-b', name: 'B').toMap(),
      ]);

      final result = await repository.findAll(workspaceId: 'ws-1');

      expect(result.valueOrNull!.map((h) => h.name), ['A', 'B']);
    });

    test('returns an empty list, not a failure, when no habits exist', () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });

  group('HabitRepository.findByStatus', () {
    test('scopes the DAO call by status', () async {
      executor.queryResults.add([_row(id: 'habit-1').toMap()]);

      final result = await repository.findByStatus(
        HabitStatus.active,
        workspaceId: 'ws-1',
      );

      expect(executor.executedQueryArgs.single, ['ws-1', 'active']);
      expect(result.valueOrNull, hasLength(1));
    });
  });

  group('HabitRepository.search', () {
    test('maps the DAO query result into a HabitPage', () async {
      executor.queryResults.add([
        {'total': 1},
      ]);
      executor.queryResults.add([_row(id: 'habit-1').toMap()]);

      final result = await repository.search(
        const HabitQuery(workspaceId: 'ws-1'),
      );

      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items, hasLength(1));
    });
  });

  group('HabitRepository.save', () {
    test('inserts a new habit when it does not already exist', () async {
      final result = await repository.save(_habit(id: 'habit-new'));

      expect(result.isSuccess, isTrue);
      final insertSql =
          executor.executedStatements.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO habits'));
    });

    test('updates an existing habit instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      final result = await repository.save(_habit(id: 'habit-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql =
          executor.executedStatements.firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE habits SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('write failed');
      final result = await repository.save(_habit());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });
  });

  group('HabitRepository.softDelete', () {
    test('delegates directly to HabitDao.softDelete', () async {
      final result = await repository.softDelete(
        const HabitId('habit-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const HabitId('habit-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<HabitsException>());
    });
  });
}
