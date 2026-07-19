import 'package:feature_finance/finance.dart';

/// Wraps a mutable, swappable [IFinanceDatabaseExecutor] delegate.
///
/// Registered once with [FinanceStorageModule] and never itself replaced —
/// every Finance repository/DAO resolves this single instance and holds it
/// for the app's lifetime. Swapping [switchTo] to a different concrete
/// executor (real vs. demo) therefore takes effect for every already-
/// resolved repository without any of them needing to be re-created or
/// know a swap happened (Milestone 6 Part A architecture requirement — no
/// `if (demoMode)` scattered through presentation/application code).
final class SwitchableFinanceDatabaseExecutor implements IFinanceDatabaseExecutor {
  SwitchableFinanceDatabaseExecutor(this._active);

  IFinanceDatabaseExecutor _active;

  void switchTo(IFinanceDatabaseExecutor executor) => _active = executor;

  @override
  Future<int> execute(String sql, [List<Object?> arguments = const []]) =>
      _active.execute(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?> arguments = const [],
  ]) =>
      _active.query(sql, arguments);
}

/// The [IFinanceTransactionRunner] counterpart of
/// [SwitchableFinanceDatabaseExecutor] — swapped together, always in the same
/// direction, so a transaction never runs against a runner/executor pair
/// from two different data sources.
final class SwitchableFinanceTransactionRunner implements IFinanceTransactionRunner {
  SwitchableFinanceTransactionRunner(this._active);

  IFinanceTransactionRunner _active;

  void switchTo(IFinanceTransactionRunner runner) => _active = runner;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IFinanceDatabaseExecutor transactionalExecutor) action,
  ) =>
      _active.runInTransaction(action);
}
