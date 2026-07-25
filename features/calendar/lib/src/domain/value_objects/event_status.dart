/// The lifecycle state of an [Event] (mirrors `NoteStatus`'s
/// active/archived domain-owned enum pattern — Calendar events don't need
/// Habits' streak-tracking complexity).
///
/// An Event is either upcoming/kept ([active]) or has been retired from the
/// visible list ([archived]). There is no "completed" state — archiving is
/// the only lifecycle transition an Event supports.
enum EventStatus { active, archived }

/// The approved transition table — mirrors `NoteStatusTransitions`. Pure
/// lookup — no I/O, no side effects.
extension EventStatusTransitions on EventStatus {
  /// The set of statuses [this] may transition to. Empty for
  /// [EventStatus.archived] — archived is terminal.
  Set<EventStatus> get allowedNextStatuses => switch (this) {
        EventStatus.active => const {EventStatus.archived},
        EventStatus.archived => const {},
      };

  /// Whether transitioning from [this] to [next] is permitted.
  bool canTransitionTo(EventStatus next) => allowedNextStatuses.contains(next);
}
