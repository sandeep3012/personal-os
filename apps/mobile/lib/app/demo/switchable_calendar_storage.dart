import 'package:feature_calendar/calendar.dart';

/// Wraps a mutable, swappable [IEventDatabaseExecutor] delegate. Mirrors
/// `SwitchableNoteDatabaseExecutor`/`SwitchableTaskDatabaseExecutor`
/// exactly — a per-feature switchable pair, not a shared cross-feature
/// abstraction.
///
/// Registered once with [CalendarStorageModule] and never itself replaced
/// — every Calendar repository/DAO resolves this single instance and holds
/// it for the app's lifetime. Swapping [switchTo] to a different concrete
/// executor (real vs. demo) therefore takes effect for every already-resolved
/// repository without any of them needing to be re-created or know a swap
/// happened.
final class SwitchableEventDatabaseExecutor implements IEventDatabaseExecutor {
  SwitchableEventDatabaseExecutor(this._active);

  IEventDatabaseExecutor _active;

  void switchTo(IEventDatabaseExecutor executor) => _active = executor;

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

/// The [IEventTransactionRunner] counterpart of
/// [SwitchableEventDatabaseExecutor] — swapped together, always in the same
/// direction, so a transaction never runs against a runner/executor pair
/// from two different data sources. Mirrors
/// `SwitchableNoteTransactionRunner` exactly.
final class SwitchableEventTransactionRunner implements IEventTransactionRunner {
  SwitchableEventTransactionRunner(this._active);

  IEventTransactionRunner _active;

  void switchTo(IEventTransactionRunner runner) => _active = runner;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IEventDatabaseExecutor transactionalExecutor) action,
  ) =>
      _active.runInTransaction(action);
}
