import 'package:feature_notes/src/domain/events/note_archived_event.dart';
import 'package:feature_notes/src/domain/events/note_created_event.dart';
import 'package:feature_notes/src/domain/events/note_deleted_event.dart';
import 'package:feature_notes/src/domain/events/note_updated_event.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

void main() {
  final now = DateTime(2026, 1, 1);

  test('NoteCreatedEvent carries its fields', () {
    final event = NoteCreatedEvent(
      noteId: const NoteId('note-1'),
      workspaceId: _ws,
      title: 'Title',
      status: NoteStatus.active,
      timestamp: now,
    );
    expect(event.noteId, const NoteId('note-1'));
    expect(event.title, 'Title');
    expect(event.status, NoteStatus.active);
  });

  test('NoteUpdatedEvent carries its fields', () {
    final event = NoteUpdatedEvent(
      noteId: const NoteId('note-1'),
      workspaceId: _ws,
      title: 'Title',
      status: NoteStatus.active,
      timestamp: now,
    );
    expect(event.title, 'Title');
  });

  test('NoteArchivedEvent carries its fields', () {
    final event = NoteArchivedEvent(
      noteId: const NoteId('note-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.noteId, const NoteId('note-1'));
    expect(event.workspaceId, _ws);
  });

  test('NoteDeletedEvent carries its fields', () {
    final event = NoteDeletedEvent(
      noteId: const NoteId('note-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.timestamp, now);
  });
}
