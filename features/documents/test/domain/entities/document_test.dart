import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

Document _document({
  String title = 'Title',
  String type = 'Contract',
  String referenceLocation = '',
  String notes = '',
  List<String> tags = const [],
  DocumentStatus status = DocumentStatus.active,
}) {
  final now = DateTime(2026, 1, 1);
  return Document(
    id: const DocumentId('document-1'),
    workspaceId: _ws,
    title: title,
    type: type,
    referenceLocation: referenceLocation,
    notes: notes,
    tags: tags,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Document construction', () {
    test('rejects an empty title', () {
      expect(() => _document(title: '   '), throwsA(isA<DocumentsException>()));
    });

    test('rejects a title longer than 200 characters', () {
      expect(
        () => _document(title: 'a' * 201),
        throwsA(isA<DocumentsException>()),
      );
    });

    test('rejects an empty type', () {
      expect(() => _document(type: '   '), throwsA(isA<DocumentsException>()));
    });

    test('rejects a type longer than 100 characters', () {
      expect(
        () => _document(type: 'a' * 101),
        throwsA(isA<DocumentsException>()),
      );
    });

    test('rejects a referenceLocation longer than 2000 characters', () {
      expect(
        () => _document(referenceLocation: 'a' * 2001),
        throwsA(isA<DocumentsException>()),
      );
    });

    test('rejects notes longer than 20000 characters', () {
      expect(
        () => _document(notes: 'a' * 20001),
        throwsA(isA<DocumentsException>()),
      );
    });

    test('normalizes tags: trims, drops empties, and dedupes', () {
      final document = _document(tags: [' work ', '', 'work', 'urgent']);
      expect(document.tags, ['work', 'urgent']);
    });

    test('defaults referenceLocation and notes to empty string', () {
      final document = _document();
      expect(document.referenceLocation, '');
      expect(document.notes, '');
    });
  });

  group('Document.copyWith', () {
    test('replaces only the supplied fields', () {
      final document = _document(title: 'Original', type: 'Receipt');
      final updated = document.copyWith(title: 'Renamed');

      expect(updated.title, 'Renamed');
      expect(updated.type, 'Receipt');
      expect(updated.status, document.status);
    });

    test('never changes status', () {
      final document = _document();
      final updated = document.copyWith(title: 'X');
      expect(updated.status, DocumentStatus.active);
    });
  });

  group('Document.transitionTo', () {
    test('allows active -> archived', () {
      final document = _document();
      final archived = document.transitionTo(
        DocumentStatus.archived,
        now: DateTime(2026, 2, 1),
      );

      expect(archived.status, DocumentStatus.archived);
      expect(archived.updatedAt, DateTime(2026, 2, 1));
    });

    test('rejects archived -> archived', () {
      final document = _document(status: DocumentStatus.archived);
      expect(
        () => document.transitionTo(
          DocumentStatus.archived,
          now: DateTime(2026, 2, 1),
        ),
        throwsA(isA<DocumentsException>()),
      );
    });
  });

  group('Document equality', () {
    test('two documents with the same id are equal regardless of other fields', () {
      final a = _document(title: 'A');
      final b = _document(title: 'B');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
