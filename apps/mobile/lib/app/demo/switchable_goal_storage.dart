import 'package:feature_goals/goals.dart';

/// Wraps a mutable, swappable [IGoalDatabaseExecutor] delegate. Mirrors
/// `SwitchableTaskDatabaseExecutor`/`SwitchableFinanceDatabaseExecutor`
/// exactly — a per-feature switchable pair, not a shared cross-feature
/// abstraction.
///
/// Registered once with [GoalsStorageModule] and never itself replaced —
/// every Goals repository/DAO resolves this single instance and holds it
/// for the app's lifetime. Swapping [switchTo] to a different concrete
/// executor (real vs. demo) therefore takes effect for every already-resolved
/// repository without any of them needing to be re-created or know a swap
/// happened.
final class SwitchableGoalDatabaseExecutor implements IGoalDatabaseExecutor {
  SwitchableGoalDatabaseExecutor(this._active);

  IGoalDatabaseExecutor _active;

  void switchTo(IGoalDatabaseExecutor executor) => _active = executor;

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

/// The [IGoalTransactionRunner] counterpart of
/// [SwitchableGoalDatabaseExecutor] — swapped together, always in the same
/// direction, so a transaction never runs against a runner/executor pair
/// from two different data sources. Mirrors
/// `SwitchableTaskTransactionRunner` exactly.
final class SwitchableGoalTransactionRunner implements IGoalTransactionRunner {
  SwitchableGoalTransactionRunner(this._active);

  IGoalTransactionRunner _active;

  void switchTo(IGoalTransactionRunner runner) => _active = runner;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IGoalDatabaseExecutor transactionalExecutor) action,
  ) =>
      _active.runInTransaction(action);
}
