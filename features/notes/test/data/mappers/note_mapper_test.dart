import 'package:feature_notes/src/data/mappers/note_mapper.dart';
import 'package:feature_notes/src/data/models/note_row.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = NoteMapper();

  Note note({
    String id = 'note-1',
    String title = 'Groceries',
    String content = 'Milk, eggs',
    List<String> tags = const ['home'],
    NoteStatus status = NoteStatus.active,
  }) {
    final now = DateTime(2024, 1, 1, 10, 30);
    return Note(
      id: NoteId(id),
      workspaceId: 'ws-1',
      title: title,
      content: content,
      tags: tags,
      status: status,
      createdAt: now,
      updatedAt: DateTime(2024, 2, 1, 8),
    );
  }

  group('NoteMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(note(id: 'note-1', title: 'Groceries'));

      expect(row.noteId, 'note-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.title, 'Groceries');
      expect(row.content, 'Milk, eggs');
      expect(row.tags, ['home']);
    });

    test('maps every NoteStatus to its enum name', () {
      for (final status in NoteStatus.values) {
        final row = mapper.toRow(note(status: status));
        expect(row.status, status.name);
      }
    });

    test('always maps deletedAt to null (domain Note is never soft-deleted)',
        () {
      final row = mapper.toRow(note());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode content', () {
      final row = mapper.toRow(note(title: 'Café run ☕ 買い物'));
      expect(row.title, 'Café run ☕ 買い物');
    });
  });

  group('NoteMapper.toEntity', () {
    NoteRow row({
      String id = 'note-1',
      String title = 'Groceries',
      String content = 'Milk, eggs',
      List<String> tags = const ['home'],
      String status = 'active',
    }) {
      final now = DateTime(2024, 1, 1, 10, 30);
      return NoteRow(
        noteId: id,
        workspaceId: 'ws-1',
        title: title,
        content: content,
        tags: tags,
        status: status,
        createdAt: now,
        updatedAt: DateTime(2024, 2, 1, 8),
      );
    }

    test('maps all scalar fields', () {
      final entity = mapper.toEntity(row(id: 'note-2', title: 'Ideas'));

      expect(entity.id, const NoteId('note-2'));
      expect(entity.workspaceId, 'ws-1');
      expect(entity.title, 'Ideas');
    });

    test('converts every status column value back to its enum', () {
      for (final status in NoteStatus.values) {
        final entity = mapper.toEntity(row(status: status.name));
        expect(entity.status, status);
      }
    });

    test('throws NotesException for an unrecognized status value', () {
      expect(
        () => mapper.toEntity(row(status: 'not_a_real_status')),
        throwsA(isA<NotesException>()),
      );
    });
  });

  group('NoteMapper round-trip', () {
    test('Note -> NoteRow -> Note preserves all domain fields', () {
      final original = note(
        id: 'note-rt',
        title: 'Round Trip',
        content: 'Some details',
        tags: const ['a', 'b'],
        status: NoteStatus.active,
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.tags, original.tags);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trips an archived note', () {
      final original = note(status: NoteStatus.archived);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.status, NoteStatus.archived);
    });

    test('round-trips a note with no tags', () {
      final original = note(tags: const []);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.tags, isEmpty);
    });
  });
}
