/// Represents an active database transaction.
///
/// Obtained from [ITransactionManager.begin]. The concrete implementation
/// decides the actual transaction semantics (e.g. ACID for SQL, batch for
/// NoSQL). Business logic should not depend on any implementation-specific
/// behaviour beyond this interface.
abstract interface class ITransaction {
  /// Whether this transaction is still open (not yet committed or rolled back).
  bool get isActive;

  /// Commits all operations performed within this transaction.
  ///
  /// Throws [TransactionException] if the commit fails or the transaction is
  /// no longer active.
  Future<void> commit();

  /// Rolls back all operations performed within this transaction.
  ///
  /// Safe to call even if the transaction has already been committed (it
  /// becomes a no-op). Throws [TransactionException] on unexpected failure.
  Future<void> rollback();
}
