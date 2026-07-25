import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

Note _note({
  String title = 'Title',
  String content = '',
  List<String> tags = const [],
  NoteStatus status = NoteStatus.active,
}) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: const NoteId('note-1'),
    workspaceId: _ws,
    title: title,
    content: content,
    tags: tags,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Note construction', () {
    test('rejects an empty title', () {
      expect(() => _note(title: '   '), throwsA(isA<NotesException>()));
    });

    test('rejects a title longer than 200 characters', () {
      expect(() => _note(title: 'a' * 201), throwsA(isA<NotesException>()));
    });

    test('rejects content longer than 20000 characters', () {
      expect(
        () => _note(content: 'a' * 20001),
        throwsA(isA<NotesException>()),
      );
    });

    test('normalizes tags: trims, drops empties, and dedupes', () {
      final note = _note(tags: [' work ', '', 'work', 'urgent']);
      expect(note.tags, ['work', 'urgent']);
    });

    test('defaults content to empty string', () {
      final note = _note();
      expect(note.content, '');
    });
  });

  group('Note.copyWith', () {
    test('replaces only the supplied fields', () {
      final note = _note(title: 'Original', content: 'body');
      final updated = note.copyWith(title: 'Renamed');

      expect(updated.title, 'Renamed');
      expect(updated.content, 'body');
      expect(updated.status, note.status);
    });

    test('never changes status', () {
      final note = _note();
      final updated = note.copyWith(title: 'X');
      expect(updated.status, NoteStatus.active);
    });
  });

  group('Note.transitionTo', () {
    test('allows active -> archived', () {
      final note = _note();
      final archived = note.transitionTo(NoteStatus.archived, now: DateTime(2026, 2, 1));

      expect(archived.status, NoteStatus.archived);
      expect(archived.updatedAt, DateTime(2026, 2, 1));
    });

    test('rejects archived -> archived', () {
      final note = _note(status: NoteStatus.archived);
      expect(
        () => note.transitionTo(NoteStatus.archived, now: DateTime(2026, 2, 1)),
        throwsA(isA<NotesException>()),
      );
    });
  });

  group('Note equality', () {
    test('two notes with the same id are equal regardless of other fields', () {
      final a = _note(title: 'A');
      final b = _note(title: 'B');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
