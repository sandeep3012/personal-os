/// The workflow state of a [Task] (DOC-032 §3, §6.1).
///
/// Domain-owned — not a platform Classification reference (DOC-032 §3
/// resolves this explicitly, unlike Finance's `CategoryId`, which is
/// deliberately opaque).
enum TaskStatus { todo, inProgress, completed, archived }

/// The approved transition table (DOC-032 §11). Pure lookup — no I/O, no
/// side effects — kept alongside the enum the same way Finance keeps
/// enum-adjacent pure logic close to its value objects.
extension TaskStatusTransitions on TaskStatus {
  /// The set of statuses [this] may transition to. Empty for [TaskStatus.archived]
  /// — archived is terminal (DOC-032 §10 Business Rule 5, §11).
  Set<TaskStatus> get allowedNextStatuses => switch (this) {
        TaskStatus.todo => const {
            TaskStatus.inProgress,
            TaskStatus.completed,
            TaskStatus.archived,
          },
        TaskStatus.inProgress => const {
            TaskStatus.completed,
            TaskStatus.archived,
          },
        TaskStatus.completed => const {TaskStatus.archived},
        TaskStatus.archived => const {},
      };

  /// Whether transitioning from [this] to [next] is permitted.
  bool canTransitionTo(TaskStatus next) => allowedNextStatuses.contains(next);
}
