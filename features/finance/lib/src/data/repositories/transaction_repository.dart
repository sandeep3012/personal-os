import 'package:feature_finance/src/data/dao/transaction_dao.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/data/mappers/transaction_mapper.dart';
import 'package:feature_finance/src/data/models/transaction_query_filter.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_page.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [ITransactionRepository].
///
/// Pure orchestration: delegates all SQL to [TransactionDao] and all
/// entity/row conversion to [TransactionMapper]. Never builds SQL, never
/// performs Money conversion, never applies business rules. [TransactionRow]
/// never escapes this class — every public method returns a domain
/// [Transaction] (or a collection/page of them).
///
/// [saveTransferPair] persists both legs inside a single atomic transaction
/// via [IFinanceTransactionRunner] — see that method for details.
final class TransactionRepository implements ITransactionRepository {
  const TransactionRepository({
    required TransactionDao transactionDao,
    required TransactionMapper transactionMapper,
    required IFinanceTransactionRunner transactionRunner,
  })  : _transactionDao = transactionDao,
        _transactionMapper = transactionMapper,
        _transactionRunner = transactionRunner;

  final TransactionDao _transactionDao;
  final TransactionMapper _transactionMapper;
  final IFinanceTransactionRunner _transactionRunner;

  @override
  FutureResult<Transaction?> findById(
    TransactionId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _transactionDao.findById(
        id.value,
        workspaceId: workspaceId,
      );
      if (row == null) return const Result.success(null);
      return Result.success(_transactionMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Transaction>> findByAccount(
    AccountId accountId, {
    required String workspaceId,
    DateRange? dateRange,
  }) async {
    try {
      final rows = await _transactionDao.findByAccount(
        accountId.value,
        workspaceId: workspaceId,
        start: dateRange?.start,
        end: dateRange?.end,
      );
      return Result.success(rows.map(_transactionMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Transaction>> findByPeriod(
    FinancePeriod period, {
    required String workspaceId,
  }) async {
    try {
      final (start, end) = _periodToRange(period);
      final rows = await _transactionDao.findByPeriod(
        workspaceId,
        start: start,
        end: end,
      );
      return Result.success(rows.map(_transactionMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Transaction>> findByCategory(
    CategoryId categoryId, {
    required String workspaceId,
    FinancePeriod? period,
  }) async {
    try {
      DateTime? start;
      DateTime? end;
      if (period != null) {
        (start, end) = _periodToRange(period);
      }
      final rows = await _transactionDao.findByCategory(
        categoryId.value,
        workspaceId: workspaceId,
        start: start,
        end: end,
      );
      return Result.success(rows.map(_transactionMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<TransactionPage> query(TransactionQuery query) async {
    try {
      final filter = TransactionQueryFilter(
        workspaceId: query.workspaceId,
        accountId: query.accountId?.value,
        categoryId: query.categoryId?.value,
        transactionType: query.type?.name,
        startDate: query.dateRange?.start,
        endDate: query.dateRange?.end,
        payeeContains: query.payeeNameContains,
        pageIndex: query.pageIndex,
        pageSize: query.pageSize,
      );
      final result = await _transactionDao.query(filter);
      final end = (query.pageIndex + 1) * query.pageSize;

      return Result.success(TransactionPage(
        items: result.items.map(_transactionMapper.toEntity).toList(),
        totalCount: result.totalCount,
        hasNextPage: end < result.totalCount,
      ));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Transaction>> findActiveByAccount(
    AccountId accountId, {
    required String workspaceId,
  }) async {
    try {
      final rows = await _transactionDao.findByAccount(
        accountId.value,
        workspaceId: workspaceId,
      );
      return Result.success(rows.map(_transactionMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Transaction transaction) async {
    try {
      final row = _transactionMapper.toRow(transaction);
      final alreadyExists = await _transactionDao.exists(
        transaction.id.value,
        workspaceId: transaction.workspaceId,
      );
      if (alreadyExists) {
        await _transactionDao.update(row);
      } else {
        await _transactionDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  /// Persists [debit] and [credit] as a single atomic unit (DOC-031 R3).
  ///
  /// Both legs are mapped and inserted inside one call to
  /// [IFinanceTransactionRunner.runInTransaction]: if either mapping or
  /// either insert fails, the transaction is rolled back and neither row is
  /// retained. The repository trusts that [debit]/[credit] are already
  /// valid — [TransferService] and the domain entity constructors are
  /// responsible for that; this method performs no business validation.
  @override
  FutureResult<void> saveTransferPair(
    Transaction debit,
    Transaction credit,
  ) async {
    try {
      await _transactionRunner.runInTransaction((transactionalExecutor) async {
        final transactionalDao = TransactionDao(transactionalExecutor);
        final debitRow = _transactionMapper.toRow(debit);
        final creditRow = _transactionMapper.toRow(credit);
        await transactionalDao.insert(debitRow);
        await transactionalDao.insert(creditRow);
      });
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    TransactionId id, {
    required String workspaceId,
  }) async {
    try {
      await _transactionDao.softDelete(
        id.value,
        workspaceId: workspaceId,
        deletedAt: DateTime.now(),
      );
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  (DateTime start, DateTime end) _periodToRange(FinancePeriod period) {
    final start = DateTime(period.year, period.month);
    // DateTime(y, m+1, 0) is the last moment of month m (handles December).
    final end = DateTime(period.year, period.month + 1, 0);
    return (start, end);
  }

  /// Translates any failure raised by the DAO or mapper into a
  /// [FinanceException] so callers never see a raw database or
  /// persistence-layer exception. Exceptions already typed as [AppException]
  /// (e.g. a mapper's data-corruption error) are passed through unchanged
  /// rather than being double-wrapped.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return FinanceException(
      message: 'Transaction repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
