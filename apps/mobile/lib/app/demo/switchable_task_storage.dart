import 'package:feature_tasks/tasks.dart';

/// Wraps a mutable, swappable [ITaskDatabaseExecutor] delegate. Mirrors
/// `SwitchableFinanceDatabaseExecutor` exactly — a per-feature switchable
/// pair, not a shared cross-feature abstraction (DOC-032 §13.4: introducing
/// one now would be a bigger, riskier change than the two-classes-per-
/// feature pattern this file continues).
///
/// Registered once with [TasksStorageModule] and never itself replaced —
/// every Tasks repository/DAO resolves this single instance and holds it for
/// the app's lifetime. Swapping [switchTo] to a different concrete executor
/// (real vs. demo) therefore takes effect for every already-resolved
/// repository without any of them needing to be re-created or know a swap
/// happened.
final class SwitchableTaskDatabaseExecutor implements ITaskDatabaseExecutor {
  SwitchableTaskDatabaseExecutor(this._active);

  ITaskDatabaseExecutor _active;

  void switchTo(ITaskDatabaseExecutor executor) => _active = executor;

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

/// The [ITaskTransactionRunner] counterpart of
/// [SwitchableTaskDatabaseExecutor] — swapped together, always in the same
/// direction, so a transaction never runs against a runner/executor pair
/// from two different data sources. Mirrors
/// `SwitchableFinanceTransactionRunner` exactly.
final class SwitchableTaskTransactionRunner implements ITaskTransactionRunner {
  SwitchableTaskTransactionRunner(this._active);

  ITaskTransactionRunner _active;

  void switchTo(ITaskTransactionRunner runner) => _active = runner;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(ITaskDatabaseExecutor transactionalExecutor) action,
  ) =>
      _active.runInTransaction(action);
}
