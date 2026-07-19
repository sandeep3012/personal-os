import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';

/// Groups and sums expense transactions by category.
///
/// Pure service — no I/O, no side effects. Date filtering, workspace scoping,
/// and pagination are the repository's responsibility. This service receives
/// an already-fetched list and performs the aggregation.
///
/// Only [TransactionType.expense] transactions with a non-null
/// [Transaction.categoryId] are included. Income and transfer legs are
/// intentionally ignored — they do not contribute to category spending totals.
///
/// Multi-currency: mixing different currencies within a single category is not
/// supported in MVP. If two expense transactions share the same [CategoryId]
/// but carry different currencies, [FinanceException] is thrown.
final class CategorySummaryService {
  const CategorySummaryService();

  /// Returns a map of [CategoryId] → total [Money] for categorised expenses.
  ///
  /// Transactions that are not [TransactionType.expense], or that have a null
  /// [Transaction.categoryId], are silently skipped.
  ///
  /// Throws [FinanceException] if two expenses for the same category carry
  /// different currencies.
  Map<CategoryId, Money> summarizeByCategory(List<Transaction> transactions) {
    final result = <CategoryId, Money>{};

    for (final txn in transactions) {
      if (txn.type != TransactionType.expense) continue;
      final categoryId = txn.categoryId;
      if (categoryId == null) continue;

      final incoming = txn.amount;
      final existing = result[categoryId];

      if (existing != null && existing.currency != incoming.currency) {
        throw FinanceException(
          message: 'CategorySummaryService: currency mismatch for category '
              '"${categoryId.value}". Expected ${existing.currency.value}, '
              'got ${incoming.currency.value}. Multi-currency category '
              'summaries are not supported in MVP.',
        );
      }

      result[categoryId] = existing == null
          ? Money(amount: incoming.amount, currency: incoming.currency)
          : Money(
              amount: existing.amount + incoming.amount,
              currency: incoming.currency,
            );
    }

    return result;
  }
}
