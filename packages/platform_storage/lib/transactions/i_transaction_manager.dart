import 'package:platform_core/result/result.dart';
import 'package:platform_storage/transactions/i_transaction.dart';

/// Manages the lifecycle of database transactions.
///
/// [ITransactionManager] is the single entry point for beginning a new
/// transaction. Use [execute] for the common "run everything in one
/// transaction, rollback on error" pattern.
///
/// Example:
/// ```dart
/// final result = await txManager.execute((tx) async {
///   await accountRepo.debit(tx, fromId, amount);
///   await accountRepo.credit(tx, toId, amount);
/// });
/// ```
abstract interface class ITransactionManager {
  /// Opens a new transaction and returns it.
  ///
  /// The caller is responsible for calling [ITransaction.commit] or
  /// [ITransaction.rollback]. Prefer [execute] to avoid forgetting to close
  /// the transaction.
  Future<Result<ITransaction>> begin();

  /// Runs [action] inside a transaction, committing on success and rolling
  /// back on any error.
  ///
  /// Returns [Result.success(T)] if [action] completes without throwing, or
  /// [Result.failure] wrapping a [TransactionException] if the action throws
  /// or the commit fails.
  ///
  /// The [ITransaction] passed to [action] must not be used after [execute]
  /// returns — it is owned by this manager.
  Future<Result<T>> execute<T>(
    Future<T> Function(ITransaction transaction) action,
  );
}
