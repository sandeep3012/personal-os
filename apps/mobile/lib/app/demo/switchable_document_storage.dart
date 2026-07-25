import 'package:feature_documents/documents.dart';

/// Wraps a mutable, swappable [IDocumentDatabaseExecutor] delegate. Mirrors
/// `SwitchableAssetDatabaseExecutor`/`SwitchableEventDatabaseExecutor`
/// exactly — a per-feature switchable pair, not a shared cross-feature
/// abstraction.
///
/// Registered once with [DocumentsStorageModule] and never itself replaced —
/// every Documents repository/DAO resolves this single instance and holds it
/// for the app's lifetime. Swapping [switchTo] to a different concrete
/// executor (real vs. demo) therefore takes effect for every already-resolved
/// repository without any of them needing to be re-created or know a swap
/// happened.
final class SwitchableDocumentDatabaseExecutor implements IDocumentDatabaseExecutor {
  SwitchableDocumentDatabaseExecutor(this._active);

  IDocumentDatabaseExecutor _active;

  void switchTo(IDocumentDatabaseExecutor executor) => _active = executor;

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

/// The [IDocumentTransactionRunner] counterpart of
/// [SwitchableDocumentDatabaseExecutor] — swapped together, always in the
/// same direction, so a transaction never runs against a runner/executor
/// pair from two different data sources. Mirrors
/// `SwitchableAssetTransactionRunner` exactly.
final class SwitchableDocumentTransactionRunner implements IDocumentTransactionRunner {
  SwitchableDocumentTransactionRunner(this._active);

  IDocumentTransactionRunner _active;

  void switchTo(IDocumentTransactionRunner runner) => _active = runner;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IDocumentDatabaseExecutor transactionalExecutor) action,
  ) =>
      _active.runInTransaction(action);
}
