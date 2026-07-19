import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';

/// Computes the current balance of an Account from its transaction history.
///
/// Pure service — no I/O, no side effects. The caller is responsible for
/// supplying only the transactions that belong to the account being evaluated.
/// Soft-deleted records must be excluded by the repository before this service
/// is invoked.
///
/// Transfer legs must arrive as [TransactionType.expense] (debit) or
/// [TransactionType.income] (credit), as produced by [TransferService].
/// Passing a raw [TransactionType.transfer] transaction is a caller error and
/// throws [FinanceException].
final class BalanceCalculationService {
  const BalanceCalculationService();

  /// Returns [initialBalance] adjusted by every transaction in [transactions].
  ///
  /// - Income adds to the running total.
  /// - Expense subtracts from the running total.
  /// - Transactions of type [TransactionType.transfer] throw [FinanceException]:
  ///   transfer legs must be typed as expense or income by [TransferService].
  Money calculateBalance(
    Money initialBalance,
    List<Transaction> transactions,
  ) {
    var running = initialBalance.amount;

    for (final txn in transactions) {
      switch (txn.type) {
        case TransactionType.income:
          running = running + txn.amount.amount;
        case TransactionType.expense:
          running = running - txn.amount.amount;
        case TransactionType.transfer:
          throw FinanceException(
            message: 'BalanceCalculationService encountered a transaction with '
                'TransactionType.transfer (id: ${txn.id}). Transfer legs must '
                'be typed as expense (debit) or income (credit) by '
                'TransferService before balance calculation.',
          );
      }
    }

    return Money(amount: running, currency: initialBalance.currency);
  }
}
