/// The lifecycle state of a [Goal] (mirrors `HabitStatus`/`TaskStatus`
/// domain-owned enum pattern).
///
/// A Goal moves through three states: it is being actively pursued
/// ([active]), it has been fully achieved ([completed]), or it has been
/// retired without being achieved ([archived]).
enum GoalStatus { active, completed, archived }

/// The approved transition table — mirrors `HabitStatusTransitions`. Pure
/// lookup — no I/O, no side effects.
extension GoalStatusTransitions on GoalStatus {
  /// The set of statuses [this] may transition to. Empty for
  /// [GoalStatus.archived] — archived is terminal.
  Set<GoalStatus> get allowedNextStatuses => switch (this) {
        GoalStatus.active => const {
            GoalStatus.completed,
            GoalStatus.archived,
          },
        GoalStatus.completed => const {GoalStatus.archived},
        GoalStatus.archived => const {},
      };

  /// Whether transitioning from [this] to [next] is permitted.
  bool canTransitionTo(GoalStatus next) => allowedNextStatuses.contains(next);
}
