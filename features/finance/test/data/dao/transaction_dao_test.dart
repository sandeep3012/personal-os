import 'package:feature_finance/src/data/dao/transaction_dao.dart';
import 'package:feature_finance/src/data/models/transaction_query_filter.dart';
import 'package:feature_finance/src/data/models/transaction_row.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_finance_database_executor.dart';

TransactionRow _row({
  String id = 'txn-1',
  String workspaceId = 'ws-1',
  String accountId = 'acc-1',
  String? transferPairId,
  String? categoryId,
  String type = 'expense',
  DateTime? date,
}) {
  final now = date ?? DateTime(2024, 6, 15);
  return TransactionRow(
    transactionId: id,
    workspaceId: workspaceId,
    accountId: accountId,
    transferPairId: transferPairId,
    categoryId: categoryId,
    amountMinor: 10000,
    currency: 'INR',
    transactionDate: now,
    transactionType: type,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFinanceDatabaseExecutor executor;
  late TransactionDao dao;

  setUp(() {
    executor = FakeFinanceDatabaseExecutor();
    dao = TransactionDao(executor);
  });

  group('TransactionDao.insert', () {
    test('issues a parameterized INSERT with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO ${FinanceSchema.transactionsTable}'));
      for (final column in FinanceSchema.transactionColumns) {
        expect(sql, contains(column));
      }
      expect(sql, isNot(contains('txn-1')));
    });

    test('binds column values in FinanceSchema.transactionColumns order',
        () async {
      final row = _row();
      await dao.insert(row);

      expect(executor.executedStatementArgs.single, row.toMap().values.toList());
    });
  });

  group('TransactionDao.update', () {
    test('issues a parameterized UPDATE excluding transaction_id from SET',
        () async {
      await dao.update(_row(id: 'txn-2'));

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE ${FinanceSchema.transactionsTable} SET'));
      final setClause = sql.split('WHERE').first;
      expect(setClause, isNot(contains('${FinanceSchema.transactionId} = ?')));
    });

    test('args end with the transaction_id used for the WHERE clause',
        () async {
      await dao.update(_row(id: 'txn-2'));

      expect(executor.executedStatementArgs.single.last, 'txn-2');
    });
  });

  group('TransactionDao.findById', () {
    test('filters by transaction_id, workspace_id, excludes soft-deleted',
        () async {
      await dao.findById('txn-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.transactionId} = ?'));
      expect(sql, contains('${FinanceSchema.transactionWorkspaceId} = ?'));
      expect(sql, contains('${FinanceSchema.transactionDeletedAt} IS NULL'));
      expect(executor.executedQueryArgs.single, ['txn-1', 'ws-1']);
    });

    test('maps the returned row', () async {
      final row = _row();
      executor.queryResults.add([row.toMap()]);

      expect(await dao.findById('txn-1', workspaceId: 'ws-1'), row);
    });

    test('returns null when no row matches', () async {
      expect(await dao.findById('missing', workspaceId: 'ws-1'), isNull);
    });
  });

  group('TransactionDao.findByAccount', () {
    test('filters by account_id and workspace_id, orders by date descending',
        () async {
      await dao.findByAccount('acc-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.transactionAccountId} = ?'));
      expect(sql, contains('${FinanceSchema.transactionWorkspaceId} = ?'));
      expect(sql, contains('${FinanceSchema.transactionDeletedAt} IS NULL'));
      expect(sql, contains('ORDER BY ${FinanceSchema.transactionDate} DESC'));
      expect(executor.executedQueryArgs.single, ['acc-1', 'ws-1']);
    });

    test('adds date-range conditions only when start/end are supplied',
        () async {
      final start = DateTime(2024, 6, 1);
      final end = DateTime(2024, 6, 30);
      await dao.findByAccount('acc-1', workspaceId: 'ws-1', start: start, end: end);

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.transactionDate} >= ?'));
      expect(sql, contains('${FinanceSchema.transactionDate} <= ?'));
      expect(
        executor.executedQueryArgs.single,
        ['acc-1', 'ws-1', start.toIso8601String(), end.toIso8601String()],
      );
    });

    test('omits date-range conditions when start/end are null', () async {
      await dao.findByAccount('acc-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, isNot(contains('${FinanceSchema.transactionDate} >=')));
      expect(sql, isNot(contains('${FinanceSchema.transactionDate} <=')));
    });

    test('maps all returned rows in order', () async {
      final rowA = _row(id: 't1', date: DateTime(2024, 6, 20));
      final rowB = _row(id: 't2', date: DateTime(2024, 6, 5));
      executor.queryResults.add([rowA.toMap(), rowB.toMap()]);

      final result = await dao.findByAccount('acc-1', workspaceId: 'ws-1');
      expect(result, [rowA, rowB]);
    });
  });

  group('TransactionDao.findByPeriod', () {
    test('filters by workspace_id and date range, no account/category filter',
        () async {
      final start = DateTime(2024, 6, 1);
      final end = DateTime(2024, 6, 30);
      await dao.findByPeriod('ws-1', start: start, end: end);

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.transactionWorkspaceId} = ?'));
      expect(sql, contains('${FinanceSchema.transactionDate} >= ?'));
      expect(sql, contains('${FinanceSchema.transactionDate} <= ?'));
      expect(sql, isNot(contains('${FinanceSchema.transactionAccountId} = ?')));
      expect(sql, isNot(contains('${FinanceSchema.transactionCategoryId} = ?')));
      expect(
        executor.executedQueryArgs.single,
        ['ws-1', start.toIso8601String(), end.toIso8601String()],
      );
    });
  });

  group('TransactionDao.findByCategory', () {
    test('filters by category_id and workspace_id', () async {
      await dao.findByCategory('cat-food', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.transactionCategoryId} = ?'));
      expect(sql, contains('${FinanceSchema.transactionWorkspaceId} = ?'));
      expect(executor.executedQueryArgs.single, ['cat-food', 'ws-1']);
    });

    test('adds date-range conditions only when supplied', () async {
      final start = DateTime(2024, 6, 1);
      await dao.findByCategory('cat-food', workspaceId: 'ws-1', start: start);

      final sql = executor.executedQueries.single;
      expect(sql, contains('${FinanceSchema.transactionDate} >= ?'));
      expect(sql, isNot(contains('${FinanceSchema.transactionDate} <=')));
    });
  });

  group('TransactionDao.query', () {
    test('always filters by workspace_id and excludes soft-deleted rows',
        () async {
      executor.queryResults
        ..add([
          {'total': 0},
        ])
        ..add([]);

      await dao.query(const TransactionQueryFilter(workspaceId: 'ws-1'));

      final countSql = executor.executedQueries[0];
      expect(countSql, contains('SELECT COUNT(*) AS total'));
      expect(countSql, contains('${FinanceSchema.transactionWorkspaceId} = ?'));
      expect(countSql, contains('${FinanceSchema.transactionDeletedAt} IS NULL'));
    });

    test('adds accountId, categoryId, type filters only when set', () async {
      executor.queryResults
        ..add([
          {'total': 0},
        ])
        ..add([]);

      await dao.query(const TransactionQueryFilter(
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        categoryId: 'cat-food',
        transactionType: 'expense',
      ));

      final countSql = executor.executedQueries[0];
      expect(countSql, contains('${FinanceSchema.transactionAccountId} = ?'));
      expect(countSql, contains('${FinanceSchema.transactionCategoryId} = ?'));
      expect(countSql, contains('${FinanceSchema.transactionType} = ?'));
      expect(
        executor.executedQueryArgs[0],
        ['ws-1', 'acc-1', 'cat-food', 'expense'],
      );
    });

    test('adds a parameterized LIKE filter for payeeContains', () async {
      executor.queryResults
        ..add([
          {'total': 0},
        ])
        ..add([]);

      await dao.query(const TransactionQueryFilter(
        workspaceId: 'ws-1',
        payeeContains: 'Amazon',
      ));

      final countSql = executor.executedQueries[0];
      expect(countSql, contains('LOWER(${FinanceSchema.transactionPayee}) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%amazon%');
    });

    test('paginates using LIMIT and OFFSET derived from pageIndex/pageSize',
        () async {
      executor.queryResults
        ..add([
          {'total': 50},
        ])
        ..add([]);

      await dao.query(const TransactionQueryFilter(
        workspaceId: 'ws-1',
        pageIndex: 2,
        pageSize: 10,
      ));

      final pagedSql = executor.executedQueries[1];
      expect(pagedSql, contains('LIMIT ? OFFSET ?'));
      final pagedArgs = executor.executedQueryArgs[1];
      expect(pagedArgs.last, 20); // pageIndex(2) * pageSize(10)
      expect(pagedArgs[pagedArgs.length - 2], 10); // pageSize
    });

    test('returns totalCount from the count query and items from the paged query',
        () async {
      final row = _row();
      executor.queryResults
        ..add([
          {'total': 7},
        ])
        ..add([row.toMap()]);

      final result = await dao.query(
        const TransactionQueryFilter(workspaceId: 'ws-1'),
      );

      expect(result.totalCount, 7);
      expect(result.items, [row]);
    });

    test('orders paged results by transaction_date descending', () async {
      executor.queryResults
        ..add([
          {'total': 0},
        ])
        ..add([]);

      await dao.query(const TransactionQueryFilter(workspaceId: 'ws-1'));

      final pagedSql = executor.executedQueries[1];
      expect(pagedSql, contains('ORDER BY ${FinanceSchema.transactionDate} DESC'));
    });
  });

  group('TransactionDao.findTransferPair', () {
    test('issues a self-join query keyed by transfer_pair_id', () async {
      await dao.findTransferPair('txn-debit', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('JOIN'));
      expect(sql, contains(FinanceSchema.transactionTransferPairId));
      expect(executor.executedQueryArgs.single, ['txn-debit', 'ws-1']);
    });

    test('maps the counterpart row when found', () async {
      final counterpart = _row(id: 'txn-credit', type: 'income');
      executor.queryResults.add([counterpart.toMap()]);

      final result =
          await dao.findTransferPair('txn-debit', workspaceId: 'ws-1');

      expect(result, counterpart);
    });

    test('returns null when no counterpart is found', () async {
      final result =
          await dao.findTransferPair('txn-solo', workspaceId: 'ws-1');
      expect(result, isNull);
    });
  });

  group('TransactionDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by transaction_id and workspace_id',
        () async {
      final deletedAt = DateTime(2024, 6, 15, 12);
      await dao.softDelete('txn-1', workspaceId: 'ws-1', deletedAt: deletedAt);

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET ${FinanceSchema.transactionDeletedAt} = ?'));
      expect(sql, contains('${FinanceSchema.transactionUpdatedAt} = ?'));
      expect(
        executor.executedStatementArgs.single,
        [deletedAt.toIso8601String(), deletedAt.toIso8601String(), 'txn-1', 'ws-1'],
      );
    });
  });

  group('TransactionDao.restore', () {
    test('clears deleted_at, sets updated_at, and requires deleted_at IS NOT NULL',
        () async {
      final restoredAt = DateTime(2024, 6, 16, 9);
      await dao.restore('txn-1', workspaceId: 'ws-1', restoredAt: restoredAt);

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET ${FinanceSchema.transactionDeletedAt} = ?'));
      expect(sql, contains('${FinanceSchema.transactionUpdatedAt} = ?'));
      expect(sql, contains('${FinanceSchema.transactionDeletedAt} IS NOT NULL'));
      expect(
        executor.executedStatementArgs.single,
        [null, restoredAt.toIso8601String(), 'txn-1', 'ws-1'],
      );
    });
  });

  group('TransactionDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query', () async {
      await dao.exists('txn-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
    });

    test('returns true when a row is found, false otherwise', () async {
      expect(await dao.exists('missing', workspaceId: 'ws-1'), isFalse);

      executor.queryResults.add([
        {'1': 1},
      ]);
      expect(await dao.exists('txn-1', workspaceId: 'ws-1'), isTrue);
    });
  });
}
