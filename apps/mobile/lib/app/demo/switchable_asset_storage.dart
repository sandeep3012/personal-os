import 'package:feature_assets/assets.dart';

/// Wraps a mutable, swappable [IAssetDatabaseExecutor] delegate. Mirrors
/// `SwitchableEventDatabaseExecutor`/`SwitchableNoteDatabaseExecutor`
/// exactly — a per-feature switchable pair, not a shared cross-feature
/// abstraction.
///
/// Registered once with [AssetsStorageModule] and never itself replaced —
/// every Assets repository/DAO resolves this single instance and holds it
/// for the app's lifetime. Swapping [switchTo] to a different concrete
/// executor (real vs. demo) therefore takes effect for every already-resolved
/// repository without any of them needing to be re-created or know a swap
/// happened.
final class SwitchableAssetDatabaseExecutor implements IAssetDatabaseExecutor {
  SwitchableAssetDatabaseExecutor(this._active);

  IAssetDatabaseExecutor _active;

  void switchTo(IAssetDatabaseExecutor executor) => _active = executor;

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

/// The [IAssetTransactionRunner] counterpart of
/// [SwitchableAssetDatabaseExecutor] — swapped together, always in the same
/// direction, so a transaction never runs against a runner/executor pair
/// from two different data sources. Mirrors
/// `SwitchableEventTransactionRunner` exactly.
final class SwitchableAssetTransactionRunner implements IAssetTransactionRunner {
  SwitchableAssetTransactionRunner(this._active);

  IAssetTransactionRunner _active;

  void switchTo(IAssetTransactionRunner runner) => _active = runner;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IAssetDatabaseExecutor transactionalExecutor) action,
  ) =>
      _active.runInTransaction(action);
}
