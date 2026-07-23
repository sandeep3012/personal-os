/// The cadence at which a [Habit] is expected to be completed (DOC-032
/// §3, adapted for Habits).
///
/// Domain-owned, mirrors how `TaskStatus` is domain-owned rather than a
/// platform Classification reference. Drives the streak-continuation window
/// evaluated by [Habit.recordCompletion]: a [daily] habit's streak survives
/// a gap of at most one day between completions; a [weekly] habit's streak
/// survives a gap of at most seven days.
enum HabitFrequency { daily, weekly }

/// Pure lookup — no I/O, no side effects — kept alongside the enum, mirrors
/// `TaskStatusTransitions`.
extension HabitFrequencyWindow on HabitFrequency {
  /// The maximum number of whole days that may elapse between two
  /// consecutive completions for the streak to be considered unbroken.
  int get maxGapInDays => switch (this) {
        HabitFrequency.daily => 1,
        HabitFrequency.weekly => 7,
      };
}
