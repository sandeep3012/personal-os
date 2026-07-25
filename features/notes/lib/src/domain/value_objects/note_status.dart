/// The lifecycle state of a [Note] (mirrors `GoalStatus`/`HabitStatus`
/// domain-owned enum pattern).
///
/// A Note is either being actively kept ([active]) or has been retired from
/// the visible list ([archived]). Unlike Goals/Habits, there is no
/// "completed" state — archiving is the only lifecycle transition a Note
/// supports.
enum NoteStatus { active, archived }

/// The approved transition table — mirrors `GoalStatusTransitions`. Pure
/// lookup — no I/O, no side effects.
extension NoteStatusTransitions on NoteStatus {
  /// The set of statuses [this] may transition to. Empty for
  /// [NoteStatus.archived] — archived is terminal.
  Set<NoteStatus> get allowedNextStatuses => switch (this) {
        NoteStatus.active => const {NoteStatus.archived},
        NoteStatus.archived => const {},
      };

  /// Whether transitioning from [this] to [next] is permitted.
  bool canTransitionTo(NoteStatus next) => allowedNextStatuses.contains(next);
}
