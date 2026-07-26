import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_page.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [ITransactionRepository] for use-case unit tests.
final class FakeTransactionRepository implements ITransactionRepository {
  final List<Transaction> _store = [];

  /// Transactions removed from [_store] via [softDelete], set aside solely
  /// so [restoreTransaction] has something to reinstate — mirrors the real
  /// DAO's `deleted_at` column without changing any other method's
  /// observable behavior (a soft-deleted transaction still vanishes from
  /// [store] and every query immediately, exactly as before).
  final List<Transaction> _deletedStore = [];

  List<Transaction> get store => List.unmodifiable(_store);

  void seed(List<Transaction> transactions) {
    _store.clear();
    _store.addAll(transactions);
  }

  @override
  FutureResult<Transaction?> findById(
    TransactionId id, {
    required String workspaceId,
  }) async =>
      Result.success(_store.where((t) => t.id == id).firstOrNull);

  @override
  FutureResult<List<Transaction>> findByAccount(
    AccountId accountId, {
    required String workspaceId,
    DateRange? dateRange,
  }) async {
    final result = _store.where((t) {
      if (t.accountId != accountId) return false;
      if (dateRange != null && !dateRange.contains(t.date.value)) return false;
      return true;
    }).toList();
    return Result.success(result);
  }

  @override
  FutureResult<List<Transaction>> findByPeriod(
    FinancePeriod period, {
    required String workspaceId,
  }) async {
    final start = DateTime(period.year, period.month);
    final end = DateTime(period.year, period.month + 1, 0);
    final range = DateRange(start: start, end: end);
    final result =
        _store.where((t) => range.contains(t.date.value)).toList();
    return Result.success(result);
  }

  @override
  FutureResult<List<Transaction>> findByCategory(
    CategoryId categoryId, {
    required String workspaceId,
    FinancePeriod? period,
  }) async {
    DateRange? range;
    if (period != null) {
      range = DateRange(
        start: DateTime(period.year, period.month),
        end: DateTime(period.year, period.month + 1, 0),
      );
    }
    final result = _store.where((t) {
      if (t.categoryId != categoryId) return false;
      if (range != null && !range.contains(t.date.value)) return false;
      return true;
    }).toList();
    return Result.success(result);
  }

  @override
  FutureResult<TransactionPage> query(TransactionQuery query) async {
    final filtered = _store.where((t) {
      if (t.workspaceId != query.workspaceId) return false;
      if (query.accountId != null && t.accountId != query.accountId) {
        return false;
      }
      if (query.categoryId != null && t.categoryId != query.categoryId) {
        return false;
      }
      if (query.type != null && t.type != query.type) return false;
      if (query.dateRange != null &&
          !query.dateRange!.contains(t.date.value)) {
        return false;
      }
      if (query.payeeNameContains != null &&
          query.payeeNameContains!.isNotEmpty) {
        final name = t.payee?.value;
        if (name == null) return false;
        if (!name
            .toLowerCase()
            .contains(query.payeeNameContains!.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    final total = filtered.length;
    final start = query.pageIndex * query.pageSize;
    final end = (start + query.pageSize).clamp(0, total);
    final items =
        start >= total ? <Transaction>[] : filtered.sublist(start, end);

    return Result.success(TransactionPage(
      items: List.unmodifiable(items),
      totalCount: total,
      hasNextPage: end < total,
    ));
  }

  @override
  FutureResult<List<Transaction>> findActiveByAccount(
    AccountId accountId, {
    required String workspaceId,
  }) async {
    final result =
        _store.where((t) => t.accountId == accountId).toList();
    return Result.success(result);
  }

  @override
  FutureResult<void> save(Transaction transaction) async {
    _store.removeWhere((t) => t.id == transaction.id);
    _store.add(transaction);
    return const Result.success(null);
  }

  @override
  FutureResult<void> saveTransferPair(
    Transaction debit,
    Transaction credit,
  ) async {
    _store.removeWhere((t) => t.id == debit.id || t.id == credit.id);
    _store.add(debit);
    _store.add(credit);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(
    TransactionId id, {
    required String workspaceId,
  }) async {
    final index = _store.indexWhere((t) => t.id == id);
    if (index != -1) _deletedStore.add(_store.removeAt(index));
    return const Result.success(null);
  }

  @override
  FutureResult<void> restoreTransaction(
    TransactionId id, {
    required String workspaceId,
  }) async {
    final index = _deletedStore.indexWhere((t) => t.id == id);
    if (index != -1) _store.add(_deletedStore.removeAt(index));
    return const Result.success(null);
  }
}
