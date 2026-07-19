import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/data/dao/transaction_dao.dart';
import 'package:feature_finance/src/data/mappers/transaction_mapper.dart';
import 'package:feature_finance/src/data/models/transaction_row.dart';
import 'package:feature_finance/src/data/repositories/transaction_repository.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../dao/fake_finance_database_executor.dart';
import 'fake_finance_transaction_runner.dart';

// Mirrors account_repository_test.dart's approach: real TransactionDao +
// TransactionMapper (both `final class`, unmockable from outside their
// library) driven by FakeFinanceDatabaseExecutor. This does not duplicate
// the Step 2 DAO SQL-shape tests; it verifies repository-level
// orchestration, entity mapping, and failure translation.

TransactionRow _row({
  String id = 'txn-1',
  String workspaceId = 'ws-1',
  String accountId = 'acc-1',
  String type = 'expense',
  DateTime? date,
}) {
  final d = date ?? DateTime(2024, 6, 15);
  return TransactionRow(
    transactionId: id,
    workspaceId: workspaceId,
    accountId: accountId,
    amountMinor: 10000,
    currency: 'INR',
    transactionDate: d,
    transactionType: type,
    createdAt: d,
    updatedAt: d,
  );
}

Transaction _transaction({
  String id = 'txn-1',
  String workspaceId = 'ws-1',
  String accountId = 'acc-1',
  TransactionType type = TransactionType.expense,
  TransactionId? transferCounterpartId,
  String currency = 'INR',
}) {
  final cc = CurrencyCode(currency);
  final now = DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: workspaceId,
    accountId: AccountId(accountId),
    type: type,
    amount: Money(amount: Decimal.parse('100'), currency: cc),
    date: TransactionDate(now),
    transferCounterpartId: transferCounterpartId,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFinanceDatabaseExecutor executor;
  late FakeFinanceTransactionRunner transactionRunner;
  late TransactionRepository repository;

  setUp(() {
    executor = FakeFinanceDatabaseExecutor();
    transactionRunner = FakeFinanceTransactionRunner(executor);
    repository = TransactionRepository(
      transactionDao: TransactionDao(executor),
      transactionMapper: const TransactionMapper(),
      transactionRunner: transactionRunner,
    );
  });

  group('TransactionRepository.findById', () {
    test('invokes the DAO and returns a mapped Transaction', () async {
      executor.queryResults.add([_row(id: 'txn-1').toMap()]);

      final result = await repository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isA<Transaction>());
      expect(result.valueOrNull!.id, const TransactionId('txn-1'));
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const TransactionId('missing'),
        workspaceId: 'ws-1',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure', () async {
      executor.queryError = Exception('db locked');
      final result = await repository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(result.exceptionOrNull!.message, contains('db locked'));
    });
  });

  group('TransactionRepository.findByAccount', () {
    test('translates DateRange into DAO start/end and maps rows', () async {
      executor.queryResults.add([_row(id: 'txn-1').toMap()]);

      final result = await repository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
        dateRange: DateRange(
          start: DateTime(2024, 6, 1),
          end: DateTime(2024, 6, 30),
        ),
      );

      final sql = executor.executedQueries.single;
      expect(sql, contains('transaction_date >= ?'));
      expect(sql, contains('transaction_date <= ?'));
      expect(result.valueOrNull, hasLength(1));
    });

    test('omits date bounds when dateRange is null', () async {
      await repository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );

      final sql = executor.executedQueries.single;
      expect(sql, isNot(contains('transaction_date >=')));
    });
  });

  group('TransactionRepository.findByPeriod', () {
    test('converts FinancePeriod to a month-wide date range', () async {
      await repository.findByPeriod(
        FinancePeriod(year: 2024, month: 6),
        workspaceId: 'ws-1',
      );

      final args = executor.executedQueryArgs.single;
      expect(args[1], DateTime(2024, 6, 1).toIso8601String());
      expect(args[2], DateTime(2024, 6, 30).toIso8601String());
    });

    test('handles the December month-boundary correctly', () async {
      await repository.findByPeriod(
        FinancePeriod(year: 2024, month: 12),
        workspaceId: 'ws-1',
      );

      final args = executor.executedQueryArgs.single;
      expect(args[2], DateTime(2024, 12, 31).toIso8601String());
    });

    test('maps returned rows to Transactions', () async {
      executor.queryResults.add([_row(id: 'txn-in-period').toMap()]);
      final result = await repository.findByPeriod(
        FinancePeriod(year: 2024, month: 6),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.single.id, const TransactionId('txn-in-period'));
    });
  });

  group('TransactionRepository.findByCategory', () {
    test('passes categoryId through without a date range when period is null',
        () async {
      await repository.findByCategory(
        const CategoryId('cat-food'),
        workspaceId: 'ws-1',
      );

      final sql = executor.executedQueries.single;
      expect(sql, contains('category_id = ?'));
      expect(sql, isNot(contains('transaction_date >=')));
    });

    test('converts a supplied FinancePeriod into a date range', () async {
      await repository.findByCategory(
        const CategoryId('cat-food'),
        workspaceId: 'ws-1',
        period: FinancePeriod(year: 2024, month: 3),
      );

      final sql = executor.executedQueries.single;
      expect(sql, contains('transaction_date >= ?'));
      expect(sql, contains('transaction_date <= ?'));
    });
  });

  group('TransactionRepository.query', () {
    test('maps TransactionQuery fields into the DAO filter', () async {
      executor.queryResults
        ..add([
          {'total': 0},
        ])
        ..add([]);

      await repository.query(const TransactionQuery(
        workspaceId: 'ws-1',
        accountId: AccountId('acc-1'),
        categoryId: CategoryId('cat-food'),
        type: TransactionType.expense,
        pageIndex: 0,
        pageSize: 10,
      ));

      final countSql = executor.executedQueries[0];
      expect(countSql, contains('account_id = ?'));
      expect(countSql, contains('category_id = ?'));
      expect(countSql, contains('transaction_type = ?'));
      expect(
        executor.executedQueryArgs[0],
        ['ws-1', 'acc-1', 'cat-food', 'expense'],
      );
    });

    test('returns a TransactionPage with correctly mapped items and totalCount',
        () async {
      executor.queryResults
        ..add([
          {'total': 3},
        ])
        ..add([_row(id: 'txn-a').toMap()]);

      final result = await repository.query(
        const TransactionQuery(workspaceId: 'ws-1', pageSize: 1),
      );

      expect(result.isSuccess, isTrue);
      final page = result.valueOrNull!;
      expect(page.totalCount, 3);
      expect(page.items, hasLength(1));
      expect(page.items.first, isA<Transaction>());
      expect(page.items.first.id, const TransactionId('txn-a'));
    });

    test('computes hasNextPage from totalCount and pagination', () async {
      executor.queryResults
        ..add([
          {'total': 25},
        ])
        ..add([]);

      final result = await repository.query(
        const TransactionQuery(workspaceId: 'ws-1', pageIndex: 0, pageSize: 10),
      );

      expect(result.valueOrNull!.hasNextPage, isTrue); // (0+1)*10=10 < 25
    });

    test('hasNextPage is false on the last page', () async {
      executor.queryResults
        ..add([
          {'total': 25},
        ])
        ..add([]);

      final result = await repository.query(
        const TransactionQuery(workspaceId: 'ws-1', pageIndex: 2, pageSize: 10),
      );

      expect(result.valueOrNull!.hasNextPage, isFalse); // (2+1)*10=30 >= 25
    });

    test('translates a DAO failure during query', () async {
      executor.queryError = Exception('query failed');
      final result = await repository.query(
        const TransactionQuery(workspaceId: 'ws-1'),
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });
  });

  group('TransactionRepository.findActiveByAccount', () {
    test('queries without a date restriction and maps all rows', () async {
      executor.queryResults.add([_row(id: 'txn-1').toMap(), _row(id: 'txn-2').toMap()]);

      final result = await repository.findActiveByAccount(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );

      final sql = executor.executedQueries.single;
      expect(sql, isNot(contains('transaction_date >=')));
      expect(result.valueOrNull, hasLength(2));
    });
  });

  group('TransactionRepository.save', () {
    test('inserts a new transaction when it does not already exist', () async {
      final result = await repository.save(_transaction(id: 'txn-new'));

      expect(result.isSuccess, isTrue);
      final insertSql = executor.executedStatements
          .firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO transactions'));
    });

    test('updates an existing transaction instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      final result = await repository.save(_transaction(id: 'txn-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql = executor.executedStatements
          .firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE transactions SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('disk full');
      final result = await repository.save(_transaction());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(result.exceptionOrNull!.message, contains('disk full'));
    });
  });

  group('TransactionRepository.softDelete', () {
    test('delegates directly to TransactionDao.softDelete', () async {
      final result = await repository.softDelete(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });
  });

  group('TransactionRepository.saveTransferPair', () {
    Transaction debitLeg() => _transaction(
          id: 'txn-debit',
          accountId: 'acc-from',
          type: TransactionType.expense,
          transferCounterpartId: const TransactionId('txn-credit'),
        );
    Transaction creditLeg() => _transaction(
          id: 'txn-credit',
          accountId: 'acc-to',
          type: TransactionType.income,
          transferCounterpartId: const TransactionId('txn-debit'),
        );

    test('both rows are inserted', () async {
      final result = await repository.saveTransferPair(debitLeg(), creditLeg());

      expect(result.isSuccess, isTrue);
      final inserts =
          executor.executedStatements.where((s) => s.contains('INSERT'));
      expect(inserts, hasLength(2));
    });

    test('both counterpart ids are persisted', () async {
      await repository.saveTransferPair(debitLeg(), creditLeg());

      final debitArgs = executor.executedStatementArgs[0];
      final creditArgs = executor.executedStatementArgs[1];
      // transfer_pair_id is the 4th column per FinanceSchema.transactionColumns.
      expect(debitArgs[3], 'txn-credit');
      expect(creditArgs[3], 'txn-debit');
    });

    test('commit is called exactly once on success', () async {
      await repository.saveTransferPair(debitLeg(), creditLeg());

      expect(transactionRunner.beginCount, 1);
      expect(transactionRunner.commitCount, 1);
      expect(transactionRunner.rollbackCount, 0);
    });

    test('rollback occurs when the second insert fails, and only the first '
        'statement was attempted (no partial persistence)', () async {
      executor
        ..executeError = Exception('disk full on second insert')
        ..executeErrorOnCallIndex = 1; // 0-based: second execute() call

      final result = await repository.saveTransferPair(debitLeg(), creditLeg());

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(
        result.exceptionOrNull!.message,
        contains('disk full on second insert'),
      );
      // The second insert never durably recorded — only the first was
      // attempted before the failure aborted the unit of work.
      expect(executor.executedStatements, hasLength(1));
    });

    test('rollback is called exactly once when the second insert fails',
        () async {
      executor
        ..executeError = Exception('boom')
        ..executeErrorOnCallIndex = 1;

      await repository.saveTransferPair(debitLeg(), creditLeg());

      expect(transactionRunner.beginCount, 1);
      expect(transactionRunner.commitCount, 0);
      expect(transactionRunner.rollbackCount, 1);
    });

    test('rollback occurs when the first insert fails', () async {
      executor
        ..executeError = Exception('first insert failed')
        ..executeErrorOnCallIndex = 0;

      final result = await repository.saveTransferPair(debitLeg(), creditLeg());

      expect(result.isFailure, isTrue);
      expect(executor.executedStatements, isEmpty);
      expect(transactionRunner.commitCount, 0);
      expect(transactionRunner.rollbackCount, 1);
    });

    test('rollback occurs on a mapper failure, before any insert is attempted',
        () async {
      // An unsupported currency causes TransactionMapper.toRow to throw
      // inside the transaction callback, before any DAO call is made.
      final invalidLeg = _transaction(id: 'txn-bad', currency: 'XYZ');

      final result =
          await repository.saveTransferPair(invalidLeg, creditLeg());

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(executor.executedStatements, isEmpty);
      expect(transactionRunner.commitCount, 0);
      expect(transactionRunner.rollbackCount, 1);
    });

    test('runInTransaction is invoked exactly once per call', () async {
      await repository.saveTransferPair(debitLeg(), creditLeg());
      expect(transactionRunner.beginCount, 1);
    });

    test('translates the underlying error into a FinanceException rather '
        'than leaking it', () async {
      executor.executeError = StateError('raw database driver error');

      final result = await repository.saveTransferPair(debitLeg(), creditLeg());

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(result.exceptionOrNull, isNot(isA<StateError>()));
    });

    test('a normal TransactionDao against the same executor remains usable '
        'after a successful transfer (transfer pair query succeeds '
        'afterwards)', () async {
      final saveResult =
          await repository.saveTransferPair(debitLeg(), creditLeg());
      expect(saveResult.isSuccess, isTrue);

      // Simulate the persisted pair being queryable afterwards via a plain,
      // non-transactional TransactionDao bound to the same executor.
      executor.queryResults.add([
        _row(id: 'txn-credit', accountId: 'acc-to', type: 'income').toMap(),
      ]);

      final pairResult = await TransactionDao(executor).findTransferPair(
        'txn-debit',
        workspaceId: 'ws-1',
      );

      expect(pairResult, isNotNull);
      expect(pairResult!.transactionId, 'txn-credit');
    });
  });
}
