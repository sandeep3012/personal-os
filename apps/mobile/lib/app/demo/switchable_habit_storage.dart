import 'package:feature_habits/habits.dart';

/// Wraps a mutable, swappable [IHabitDatabaseExecutor] delegate. Mirrors
/// `SwitchableTaskDatabaseExecutor`/`SwitchableFinanceDatabaseExecutor`
/// exactly — a per-feature switchable pair, not a shared cross-feature
/// abstraction.
///
/// Registered once with [HabitsStorageModule] and never itself replaced —
/// every Habits repository/DAO resolves this single instance and holds it
/// for the app's lifetime. Swapping [switchTo] to a different concrete
/// executor (real vs. demo) therefore takes effect for every already-resolved
/// repository without any of them needing to be re-created or know a swap
/// happened.
final class SwitchableHabitDatabaseExecutor implements IHabitDatabaseExecutor {
  SwitchableHabitDatabaseExecutor(this._active);

  IHabitDatabaseExecutor _active;

  void switchTo(IHabitDatabaseExecutor executor) => _active = executor;

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

/// The [IHabitTransactionRunner] counterpart of
/// [SwitchableHabitDatabaseExecutor] — swapped together, always in the same
/// direction, so a transaction never runs against a runner/executor pair
/// from two different data sources. Mirrors
/// `SwitchableTaskTransactionRunner` exactly.
final class SwitchableHabitTransactionRunner implements IHabitTransactionRunner {
  SwitchableHabitTransactionRunner(this._active);

  IHabitTransactionRunner _active;

  void switchTo(IHabitTransactionRunner runner) => _active = runner;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IHabitDatabaseExecutor transactionalExecutor) action,
  ) =>
      _active.runInTransaction(action);
}
