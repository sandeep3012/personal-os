import 'package:feature_notes/src/data/dao/note_dao.dart';
import 'package:feature_notes/src/data/mappers/note_mapper.dart';
import 'package:feature_notes/src/data/models/note_row.dart';
import 'package:feature_notes/src/data/repositories/note_repository.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_query.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dao/fake_note_database_executor.dart';

// Mirrors Goals' goal_repository_test.dart: exercises NoteRepository against
// the real NoteDao and NoteMapper, with the fake at the
// FakeNoteDatabaseExecutor boundary.

NoteRow _row({
  String id = 'note-1',
  String workspaceId = 'ws-1',
  String title = 'Groceries',
}) {
  final now = DateTime(2024, 1, 1);
  return NoteRow(
    noteId: id,
    workspaceId: workspaceId,
    title: title,
    content: 'Milk, eggs',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

Note _note({String id = 'note-1', String workspaceId = 'ws-1'}) {
  final now = DateTime(2024, 1, 1);
  return Note(
    id: NoteId(id),
    workspaceId: workspaceId,
    title: 'Groceries',
    status: NoteStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeNoteDatabaseExecutor executor;
  late NoteRepository repository;

  setUp(() {
    executor = FakeNoteDatabaseExecutor();
    repository = NoteRepository(
      noteDao: NoteDao(executor),
      noteMapper: const NoteMapper(),
    );
  });

  group('NoteRepository.findById', () {
    test('returns a correctly mapped Note when the row exists', () async {
      executor.queryResults.add([_row(id: 'note-1', title: 'My Note').toMap()]);

      final result =
          await repository.findById(const NoteId('note-1'), workspaceId: 'ws-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'My Note');
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const NoteId('missing'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure into a NotesException', () async {
      executor.queryError = Exception('disk read error');

      final result = await repository.findById(
        const NoteId('note-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<NotesException>());
      expect(result.exceptionOrNull!.message, contains('disk read error'));
    });

    test('passes through a NotesException raised by the mapper unchanged',
        () async {
      final corruptRow = _row(id: 'note-1').toMap();
      corruptRow['status'] = 'not_a_real_status';
      executor.queryResults.add([corruptRow]);

      final result = await repository.findById(
        const NoteId('note-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull!.message, contains('Unrecognized status'));
    });
  });

  group('NoteRepository.findAll', () {
    test('maps all rows', () async {
      executor.queryResults.add([
        _row(id: 'note-a', title: 'A').toMap(),
        _row(id: 'note-b', title: 'B').toMap(),
      ]);

      final result = await repository.findAll(workspaceId: 'ws-1');

      expect(result.valueOrNull!.map((n) => n.title), ['A', 'B']);
    });

    test('returns an empty list, not a failure, when no notes exist', () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });

  group('NoteRepository.findByStatus', () {
    test('scopes the DAO call by status', () async {
      executor.queryResults.add([_row(id: 'note-1').toMap()]);

      final result = await repository.findByStatus(
        NoteStatus.active,
        workspaceId: 'ws-1',
      );

      expect(executor.executedQueryArgs.single, ['ws-1', 'active']);
      expect(result.valueOrNull, hasLength(1));
    });
  });

  group('NoteRepository.search', () {
    test('maps the DAO query result into a NotePage', () async {
      executor.queryResults.add([
        {'total': 1},
      ]);
      executor.queryResults.add([_row(id: 'note-1').toMap()]);

      final result = await repository.search(
        const NoteQuery(workspaceId: 'ws-1'),
      );

      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items, hasLength(1));
    });
  });

  group('NoteRepository.save', () {
    test('inserts a new note when it does not already exist', () async {
      final result = await repository.save(_note(id: 'note-new'));

      expect(result.isSuccess, isTrue);
      final insertSql =
          executor.executedStatements.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO notes'));
    });

    test('updates an existing note instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      final result = await repository.save(_note(id: 'note-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql =
          executor.executedStatements.firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE notes SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('write failed');
      final result = await repository.save(_note());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<NotesException>());
    });
  });

  group('NoteRepository.softDelete', () {
    test('delegates directly to NoteDao.softDelete', () async {
      final result = await repository.softDelete(
        const NoteId('note-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const NoteId('note-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<NotesException>());
    });
  });
}
