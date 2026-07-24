import 'package:application/application.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';

/// Archiving is a distinct, terminal, business-meaningful transition,
/// not an ordinary field update — mirrors `GoalArchivedEvent`.
final class NoteArchivedEvent extends DomainEvent {
  const NoteArchivedEvent({
    required this.noteId,
    required this.workspaceId,
    required this.timestamp,
  });

  final NoteId noteId;
  final String workspaceId;
  final DateTime timestamp;
}
