/// The state of a component managed by [LifecycleManager].
///
/// Valid transitions:
///
/// ```
/// uninitialized → initialized → started ⇄ paused → stopped → disposed
///                                       ↘____________↗
/// ```
///
/// Any attempt to transition outside these paths throws a
/// [LifecycleException].
enum LifecycleState {
  /// Initial state — [LifecycleManager.initialize] has not been called.
  uninitialized,

  /// [LifecycleManager.initialize] has completed.
  initialized,

  /// [LifecycleManager.start] has completed (or [resume] returned here from
  /// [paused]).
  started,

  /// [LifecycleManager.pause] has completed.
  paused,

  /// [LifecycleManager.stop] has completed.
  stopped,

  /// [LifecycleManager.dispose] has completed. Terminal state.
  disposed,
}
