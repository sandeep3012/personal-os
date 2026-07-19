/// Exposes the currently active Workspace scope to any layer that needs it.
///
/// DOC-008 establishes Workspace as a cross-cutting Platform concern with its
/// own lifecycle (Create → Initialize → Active → Suspended → Archived →
/// Deleted). [WorkspaceContext] does not implement that lifecycle — it is
/// only the read/notify pointer other layers consult for "what is the active
/// workspace right now." Orchestrating an actual workspace switch (persist
/// state, unload, load target config, restore, resume) is a future concern
/// once a real Workspace-selection feature exists.
///
/// Registered as a singleton by `ApplicationModule` (`packages/application`)
/// — never owned by a feature package (ADR-004).
///
/// Pure Dart — `packages/application` may not depend on Flutter (ADR-001), so
/// this deliberately does not extend `ChangeNotifier` (a Flutter SDK type).
/// [addListener]/[removeListener] are a minimal, manually-implemented
/// callback registration; a Flutter-aware ViewModel (which does depend on
/// Flutter, per ADR-004) subscribes and reacts to changes on its own terms
/// (e.g. by calling its own `notifyListeners()`/reloading).
final class WorkspaceContext {
  WorkspaceContext({required String initialWorkspaceId})
      : _workspaceId = initialWorkspaceId;

  /// Placeholder default workspace identifier used until a real
  /// Workspace-selection feature exists (DOC-008). Colocated with
  /// [WorkspaceContext] itself so the placeholder has exactly one owner,
  /// rather than being re-invented per feature.
  static const defaultWorkspaceId = 'default-workspace';

  String _workspaceId;
  final _listeners = <void Function()>[];

  /// The currently active workspace's identifier.
  String get workspaceId => _workspaceId;

  /// Switches the active workspace and notifies every registered listener.
  ///
  /// A no-op (no notification) if [workspaceId] is already the active one.
  void switchTo(String workspaceId) {
    if (workspaceId == _workspaceId) return;
    _workspaceId = workspaceId;
    // Iterate a snapshot so a listener that adds/removes another listener
    // during notification cannot corrupt this iteration.
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  /// Registers [listener] to be called whenever the active workspace
  /// changes via [switchTo].
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes a previously registered [listener]. Safe to call even if
  /// [listener] was never registered.
  void removeListener(void Function() listener) => _listeners.remove(listener);
}
