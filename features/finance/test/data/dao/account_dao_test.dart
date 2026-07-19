import 'package:feature_finance/src/data/dao/account_dao.dart';
import 'package:feature_finance/src/data/models/account_row.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_finance_database_executor.dart';

AccountRow _row({
  String id = 'acc-1',
  String workspaceId = 'ws-1',
  bool isActive = true,
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return AccountRow(
    accountId: id,
    workspaceId: workspaceId,
    name: 'Test Account',
    accountType: 'savings',
    currency: 'INR',
    openingBalanceMinor: 0,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeFinanceDatabaseExecutor executor;
  late AccountDao dao;

  setUp(() {
    executor = FakeFinanceDatabaseExecutor();
    dao = AccountDao(executor);
  });

  group('AccountDao.insert', () {
    test('issues a parameterized INSERT with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO ${FinanceSchema.accountsTable}'));
      for (final column in FinanceSchema.accountColumns) {
        expect(sql, contains(column));
      }
      // Parameterized: values are bound as args, never inlined into the SQL text.
      expect(sql, isNot(contains('acc-1')));
      expect(sql, isNot(contains('Test Account')));
    });

    test('binds column values in FinanceSchema.accountColumns order', () async {
      final row = _row();
      await dao.insert(row);

      expect(executor.executedStatementArgs.single, row.toMap().values.toList());
    });
  });

  group('AccountDao.update', () {
    test('issues a parameterized UPDATE excluding account_id from SET', () async {
      await dao.update(_row(id: 'acc-2'));

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE ${FinanceSchema.accountsTable} SET'));
      expect(sql, contains('WHERE ${FinanceSchema.accountId} = ?'));
      // account_id must not appear in the SET clause (only in WHERE).
      final setClause = sql.split('WHERE').first;
      expect(setClause, isNot(contains('${FinanceSchema.accountId} = ?')));
    });

    test('args end with the account_id used for the WHERE clause', () async {
      await dao.update(_row(id: 'acc-2'));

      expect(executor.executedStatementArgs.single.last, 'acc-2');
    });
  });

  group('AccountDao.findById', () {
    test('filters by account_id, workspace_id, and excludes soft-deleted rows',
        () async {
      await dao.findById('acc-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.accountId} = ?'));
      expect(sql, contains('${FinanceSchema.accountWorkspaceId} = ?'));
      expect(sql, contains('${FinanceSchema.accountDeletedAt} IS NULL'));
      expect(executor.executedQueryArgs.single, ['acc-1', 'ws-1']);
    });

    test('maps the returned row to an AccountRow', () async {
      final row = _row(id: 'acc-1');
      executor.queryResults.add([row.toMap()]);

      final result = await dao.findById('acc-1', workspaceId: 'ws-1');

      expect(result, row);
    });

    test('returns null when no row matches', () async {
      final result = await dao.findById('missing', workspaceId: 'ws-1');
      expect(result, isNull);
    });
  });

  group('AccountDao.findAll', () {
    test('filters by workspace_id, excludes soft-deleted, orders by created_at',
        () async {
      await dao.findAll('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.accountWorkspaceId} = ?'));
      expect(sql, contains('${FinanceSchema.accountDeletedAt} IS NULL'));
      expect(sql, contains('ORDER BY ${FinanceSchema.accountCreatedAt}'));
      expect(sql, isNot(contains('${FinanceSchema.accountIsActive} = 1')));
      expect(executor.executedQueryArgs.single, ['ws-1']);
    });

    test('maps all returned rows', () async {
      final rowA = _row(id: 'acc-a');
      final rowB = _row(id: 'acc-b');
      executor.queryResults.add([rowA.toMap(), rowB.toMap()]);

      final result = await dao.findAll('ws-1');

      expect(result, [rowA, rowB]);
    });

    test('returns an empty list when no rows exist', () async {
      final result = await dao.findAll('ws-1');
      expect(result, isEmpty);
    });
  });

  group('AccountDao.findActive', () {
    test('filters by workspace_id, is_active = 1, and excludes soft-deleted rows',
        () async {
      await dao.findActive('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.accountIsActive} = 1'));
      expect(sql, contains('${FinanceSchema.accountWorkspaceId} = ?'));
      expect(sql, contains('${FinanceSchema.accountDeletedAt} IS NULL'));
      expect(executor.executedQueryArgs.single, ['ws-1']);
    });

    test('maps only the returned active rows', () async {
      final activeRow = _row(id: 'acc-active');
      executor.queryResults.add([activeRow.toMap()]);

      final result = await dao.findActive('ws-1');

      expect(result, [activeRow]);
    });
  });

  group('AccountDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by account_id and workspace_id',
        () async {
      final deletedAt = DateTime(2024, 6, 15, 10);
      await dao.softDelete('acc-1', workspaceId: 'ws-1', deletedAt: deletedAt);

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET ${FinanceSchema.accountDeletedAt} = ?'));
      expect(sql, contains('${FinanceSchema.accountUpdatedAt} = ?'));
      expect(sql, contains('WHERE ${FinanceSchema.accountId} = ?'));
      expect(sql, contains('${FinanceSchema.accountWorkspaceId} = ?'));

      expect(
        executor.executedStatementArgs.single,
        [deletedAt.toIso8601String(), deletedAt.toIso8601String(), 'acc-1', 'ws-1'],
      );
    });
  });

  group('AccountDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query scoped by id and workspace',
        () async {
      await dao.exists('acc-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
      expect(sql, contains('${FinanceSchema.accountDeletedAt} IS NULL'));
      expect(executor.executedQueryArgs.single, ['acc-1', 'ws-1']);
    });

    test('returns true when a row is found', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      expect(await dao.exists('acc-1', workspaceId: 'ws-1'), isTrue);
    });

    test('returns false when no row is found', () async {
      expect(await dao.exists('missing', workspaceId: 'ws-1'), isFalse);
    });
  });
}
