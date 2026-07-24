/// The lifecycle state of a [Document] (mirrors `NoteStatus`'s
/// active/archived domain-owned enum pattern).
///
/// A Document is either being actively kept ([active]) or has been retired
/// from the visible list ([archived]). There is no "disposed" state —
/// unlike Assets, archiving is the only lifecycle transition a Document
/// supports (documents are metadata records, not owned items that can be
/// sold or written off).
enum DocumentStatus { active, archived }

/// The approved transition table — mirrors `NoteStatusTransitions`. Pure
/// lookup — no I/O, no side effects.
extension DocumentStatusTransitions on DocumentStatus {
  /// The set of statuses [this] may transition to. Empty for
  /// [DocumentStatus.archived] — archived is terminal.
  Set<DocumentStatus> get allowedNextStatuses => switch (this) {
        DocumentStatus.active => const {DocumentStatus.archived},
        DocumentStatus.archived => const {},
      };

  /// Whether transitioning from [this] to [next] is permitted.
  bool canTransitionTo(DocumentStatus next) =>
      allowedNextStatuses.contains(next);
}
