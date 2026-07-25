import 'package:application/application.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';

final class NoteDeletedEvent extends DomainEvent {
  const NoteDeletedEvent({
    required this.noteId,
    required this.workspaceId,
    required this.timestamp,
  });

  final NoteId noteId;
  final String workspaceId;
  final DateTime timestamp;
}
