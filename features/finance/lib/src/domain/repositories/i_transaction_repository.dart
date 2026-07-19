import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_page.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Transaction persistence, expressed in domain terms.
///
/// Implementations are internal to the Finance feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-deleted records are never returned — the repository enforces this
/// invariant transparently.
abstract interface class ITransactionRepository {
  /// Returns the [Transaction] with [id] within [workspaceId], or `null` if
  /// no matching transaction exists.
  FutureResult<Transaction?> findById(
    TransactionId id, {
    required String workspaceId,
  });

  /// Returns all non-deleted transactions for [accountId], optionally
  /// restricted to [dateRange].
  ///
  /// Results are ordered by transaction date descending. Returns an empty
  /// list when no transactions match — never fails for an empty result.
  FutureResult<List<Transaction>> findByAccount(
    AccountId accountId, {
    required String workspaceId,
    DateRange? dateRange,
  });

  /// Returns all non-deleted transactions across all accounts in [workspaceId]
  /// that fall within the calendar month defined by [period].
  ///
  /// Used by period-based summary use cases that aggregate across all accounts.
  /// Results are ordered by transaction date descending.
  FutureResult<List<Transaction>> findByPeriod(
    FinancePeriod period, {
    required String workspaceId,
  });

  /// Returns all non-deleted transactions assigned to [categoryId] within
  /// [workspaceId], optionally restricted to [period].
  ///
  /// Used by [CategorySummaryService] to aggregate spending per category.
  /// When [period] is null, returns all matching transactions regardless of date.
  FutureResult<List<Transaction>> findByCategory(
    CategoryId categoryId, {
    required String workspaceId,
    FinancePeriod? period,
  });

  /// Executes a [TransactionQuery] and returns a paginated [TransactionPage].
  ///
  /// [TransactionQuery.workspaceId] scopes the result set. All other filter
  /// fields are optional — absent fields impose no constraint. Pagination is
  /// controlled by [TransactionQuery.pageIndex] and [TransactionQuery.pageSize].
  FutureResult<TransactionPage> query(TransactionQuery query);

  /// Returns all non-deleted transactions for [accountId] with no date filter.
  ///
  /// Used exclusively to enforce Business Invariant 5: an account cannot be
  /// deleted while it still owns transactions. Callers check whether the
  /// returned list is non-empty before proceeding with deletion.
  FutureResult<List<Transaction>> findActiveByAccount(
    AccountId accountId, {
    required String workspaceId,
  });

  /// Persists [transaction]. Creates it if it is new; updates it if it
  /// already exists.
  FutureResult<void> save(Transaction transaction);

  /// Persists [debit] and [credit] as a single atomic unit.
  ///
  /// Either both are stored or neither is — this is the consistency boundary
  /// for all transfer operations. Implementations must execute both writes
  /// within a single database transaction.
  FutureResult<void> saveTransferPair(
    Transaction debit,
    Transaction credit,
  );

  /// Marks the transaction identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the transaction has already been removed.
  /// Implementations must use a soft-delete strategy so that balance history
  /// remains reconstructable. Soft-deleted records are excluded from all
  /// live queries by contract (Business Invariant 6).
  FutureResult<void> softDelete(
    TransactionId id, {
    required String workspaceId,
  });
}
