import 'package:feature_notes/src/data/models/note_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteRow toMap/fromMap round-trip', () {
    test('round-trips all fields including tags and nullable deletedAt', () {
      final row = NoteRow(
        noteId: 'note-1',
        workspaceId: 'ws-1',
        title: 'Groceries',
        content: 'Milk, eggs',
        tags: const ['home', 'urgent'],
        status: 'active',
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 3, 8),
        deletedAt: null,
      );

      final restored = NoteRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips a soft-deleted row', () {
      final row = NoteRow(
        noteId: 'note-2',
        workspaceId: 'ws-1',
        title: 'Archived note',
        status: 'archived',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 6),
        deletedAt: DateTime(2026, 1, 7),
      );

      final restored = NoteRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips minimal fields (no content/tags)', () {
      final row = NoteRow(
        noteId: 'note-3',
        workspaceId: 'ws-1',
        title: 'Minimal',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = NoteRow.fromMap(row.toMap());

      expect(restored, row);
      expect(restored.content, '');
      expect(restored.tags, isEmpty);
      expect(restored.deletedAt, isNull);
    });

    test('encodes tags as a pipe-delimited string', () {
      final row = NoteRow(
        noteId: 'note-4',
        workspaceId: 'ws-1',
        title: 'Tagged',
        tags: const ['work', 'urgent'],
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(row.toMap()['tags'], '|work|urgent|');
    });

    test('decodes an empty tags column back to an empty list', () {
      final restored = NoteRow.fromMap({
        'note_id': 'note-5',
        'workspace_id': 'ws-1',
        'title': 'No tags',
        'content': '',
        'tags': '',
        'status': 'active',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime(2026, 1, 1).toIso8601String(),
        'deleted_at': null,
      });

      expect(restored.tags, isEmpty);
    });
  });
}
