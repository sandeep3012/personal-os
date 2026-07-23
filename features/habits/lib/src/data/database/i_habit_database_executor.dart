/// Technology-neutral SQL execution contract used by the Habits DAO layer.
///
/// Mirrors Finance's `IFinanceDatabaseExecutor` exactly — a per-feature
/// persistence-leaf interface, not a shared cross-feature abstraction (see
/// DOC-032 §13.4 for why a shared interface was not introduced this pass).
abstract interface class IHabitDatabaseExecutor {
  /// Executes a `SELECT` statement and returns the resulting rows.
  ///
  /// [arguments] are bound positionally to `?` placeholders in [sql]. Never
  /// concatenate caller-supplied values directly into [sql].
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?> arguments = const [],
  ]);

  /// Executes an `INSERT`, `UPDATE`, or `DELETE` statement and returns the
  /// number of affected rows.
  ///
  /// [arguments] are bound positionally to `?` placeholders in [sql]. Never
  /// concatenate caller-supplied values directly into [sql].
  Future<int> execute(
    String sql, [
    List<Object?> arguments = const [],
  ]);
}
