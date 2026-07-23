/// The lifecycle state of a [Habit] (DOC-032 §3/§6.1, adapted for Habits).
///
/// Unlike Tasks' four-state workflow, a Habit has only two states: it is
/// either being actively tracked ([active]) or it has been retired
/// ([archived]). Completions are not a status — a Habit stays [active]
/// indefinitely across any number of completions; only [Habit.currentStreak]
/// and [Habit.completionLog] change as it is completed. Domain-owned, not a
/// platform Classification reference — mirrors `TaskStatus` exactly in
/// intent.
enum HabitStatus { active, archived }

/// The approved transition table — mirrors `TaskStatusTransitions`. Pure
/// lookup — no I/O, no side effects.
extension HabitStatusTransitions on HabitStatus {
  /// The set of statuses [this] may transition to. Empty for
  /// [HabitStatus.archived] — archived is terminal.
  Set<HabitStatus> get allowedNextStatuses => switch (this) {
        HabitStatus.active => const {HabitStatus.archived},
        HabitStatus.archived => const {},
      };

  /// Whether transitioning from [this] to [next] is permitted.
  bool canTransitionTo(HabitStatus next) => allowedNextStatuses.contains(next);
}
