import 'package:feature_notes/notes.dart';

/// Wraps a mutable, swappable [INoteDatabaseExecutor] delegate. Mirrors
/// `SwitchableTaskDatabaseExecutor`/`SwitchableFinanceDatabaseExecutor`
/// exactly — a per-feature switchable pair, not a shared cross-feature
/// abstraction.
///
/// Registered once with [NotesStorageModule] and never itself replaced —
/// every Notes repository/DAO resolves this single instance and holds it
/// for the app's lifetime. Swapping [switchTo] to a different concrete
/// executor (real vs. demo) therefore takes effect for every already-resolved
/// repository without any of them needing to be re-created or know a swap
/// happened.
final class SwitchableNoteDatabaseExecutor implements INoteDatabaseExecutor {
  SwitchableNoteDatabaseExecutor(this._active);

  INoteDatabaseExecutor _active;

  void switchTo(INoteDatabaseExecutor executor) => _active = executor;

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

/// The [INoteTransactionRunner] counterpart of
/// [SwitchableNoteDatabaseExecutor] — swapped together, always in the same
/// direction, so a transaction never runs against a runner/executor pair
/// from two different data sources. Mirrors
/// `SwitchableTaskTransactionRunner` exactly.
final class SwitchableNoteTransactionRunner implements INoteTransactionRunner {
  SwitchableNoteTransactionRunner(this._active);

  INoteTransactionRunner _active;

  void switchTo(INoteTransactionRunner runner) => _active = runner;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(INoteDatabaseExecutor transactionalExecutor) action,
  ) =>
      _active.runInTransaction(action);
}
