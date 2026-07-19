import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/data/dao/account_dao.dart';
import 'package:feature_finance/src/data/mappers/account_mapper.dart';
import 'package:feature_finance/src/data/models/account_row.dart';
import 'package:feature_finance/src/data/repositories/account_repository.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dao/fake_finance_database_executor.dart';

// This suite exercises AccountRepository against the *real* AccountDao and
// AccountMapper (both `final class`, so they cannot be mocked/faked from
// outside their library). The test double boundary is one layer down, at
// FakeFinanceDatabaseExecutor — already used and validated by the Step 2 DAO
// tests. This suite does not re-verify SQL shape (that's the DAO tests'
// job); it verifies that the repository orchestrates the DAO + mapper
// correctly, returns domain entities, and translates failures.

AccountRow _row({
  String id = 'acc-1',
  String workspaceId = 'ws-1',
  String name = 'Savings',
  bool isActive = true,
}) {
  final now = DateTime(2024, 1, 1);
  return AccountRow(
    accountId: id,
    workspaceId: workspaceId,
    name: name,
    accountType: 'savings',
    currency: 'INR',
    openingBalanceMinor: 0,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

Account _account({
  String id = 'acc-1',
  String workspaceId = 'ws-1',
  String name = 'Savings',
}) {
  final inr = CurrencyCode('INR');
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: workspaceId,
    name: name,
    type: AccountType.savings,
    currency: inr,
    initialBalance: Money(amount: Decimal.zero, currency: inr),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFinanceDatabaseExecutor executor;
  late AccountRepository repository;

  setUp(() {
    executor = FakeFinanceDatabaseExecutor();
    repository = AccountRepository(
      accountDao: AccountDao(executor),
      accountMapper: const AccountMapper(),
    );
  });

  group('AccountRepository.findById', () {
    test('invokes the DAO with the correct id and workspace', () async {
      await repository.findById(const AccountId('acc-1'), workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('account_id = ?'));
      expect(executor.executedQueryArgs.single, ['acc-1', 'ws-1']);
    });

    test('returns a correctly mapped Account when the row exists', () async {
      executor.queryResults.add([_row(id: 'acc-1', name: 'My Savings').toMap()]);

      final result = await repository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isA<Account>());
      expect(result.valueOrNull!.id, const AccountId('acc-1'));
      expect(result.valueOrNull!.name, 'My Savings');
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const AccountId('missing'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure into a FinanceException', () async {
      executor.queryError = Exception('disk read error');

      final result = await repository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(result.exceptionOrNull!.message, contains('disk read error'));
    });

    test('passes through a FinanceException raised by the mapper unchanged',
        () async {
      // Force a mapper failure via an unrecognized account_type.
      final corruptRow = _row(id: 'acc-1').toMap();
      corruptRow['account_type'] = 'not_a_real_type';
      executor.queryResults.add([corruptRow]);

      final result = await repository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(
        result.exceptionOrNull!.message,
        contains('Unrecognized account_type'),
      );
    });
  });

  group('AccountRepository.findAll', () {
    test('invokes the DAO scoped by workspace and maps all rows', () async {
      executor.queryResults.add([
        _row(id: 'acc-a', name: 'A').toMap(),
        _row(id: 'acc-b', name: 'B').toMap(),
      ]);

      final result = await repository.findAll(workspaceId: 'ws-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(2));
      expect(result.valueOrNull!.map((a) => a.name), ['A', 'B']);
    });

    test('returns an empty list, not a failure, when no accounts exist',
        () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('translates a DAO failure', () async {
      executor.queryError = Exception('boom');
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });
  });

  group('AccountRepository.findActive', () {
    test('invokes the DAO is_active filter and maps rows', () async {
      executor.queryResults.add([_row(id: 'acc-active').toMap()]);

      final result = await repository.findActive(workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('is_active = 1'));
      expect(result.valueOrNull, hasLength(1));
    });
  });

  group('AccountRepository.save', () {
    test('inserts a new account when it does not already exist', () async {
      final result = await repository.save(_account(id: 'acc-new'));

      expect(result.isSuccess, isTrue);
      final insertSql =
          executor.executedStatements.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO accounts'));
      expect(executor.executedStatementArgs.first, contains('acc-new'));
    });

    test('updates an existing account instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]); // exists() check finds a row

      final result = await repository.save(_account(id: 'acc-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql =
          executor.executedStatements.firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE accounts SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('write failed');
      final result = await repository.save(_account());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(result.exceptionOrNull!.message, contains('write failed'));
    });
  });

  group('AccountRepository.softDelete', () {
    test('delegates directly to AccountDao.softDelete', () async {
      final result = await repository.softDelete(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
      expect(executor.executedStatementArgs.single, containsAllInOrder(
        [anything, anything, 'acc-1', 'ws-1'],
      ));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });
  });
}
