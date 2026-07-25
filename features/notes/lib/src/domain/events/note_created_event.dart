import 'package:application/application.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';

final class NoteCreatedEvent extends DomainEvent {
  const NoteCreatedEvent({
    required this.noteId,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.timestamp,
  });

  final NoteId noteId;
  final String workspaceId;
  final String title;
  final NoteStatus status;
  final DateTime timestamp;
}
