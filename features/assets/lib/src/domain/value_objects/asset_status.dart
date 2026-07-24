/// The lifecycle state of an [Asset] (mirrors `NoteStatus`'s
/// active/archived domain-owned enum pattern, extended with a `disposed`
/// state for assets that have been sold/given away/written off).
///
/// An Asset starts [active]. It may become [disposed] (removed from active
/// holdings, e.g. sold or scrapped) or [archived] (retired from the visible
/// list without being disposed). Both [disposed] and [archived] are
/// terminal — mirrors Notes' single-terminal-state shape, just with two
/// terminal states instead of one.
enum AssetStatus { active, disposed, archived }

/// The approved transition table — mirrors `NoteStatusTransitions`. Pure
/// lookup — no I/O, no side effects.
extension AssetStatusTransitions on AssetStatus {
  /// The set of statuses [this] may transition to. Empty for [disposed] and
  /// [archived] — both are terminal.
  Set<AssetStatus> get allowedNextStatuses => switch (this) {
        AssetStatus.active => const {AssetStatus.disposed, AssetStatus.archived},
        AssetStatus.disposed => const {},
        AssetStatus.archived => const {},
      };

  /// Whether transitioning from [this] to [next] is permitted.
  bool canTransitionTo(AssetStatus next) => allowedNextStatuses.contains(next);
}
