import 'package:feature_documents/src/data/mappers/document_mapper.dart';
import 'package:feature_documents/src/data/models/document_row.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DocumentMapper();

  Document document({
    String id = 'document-1',
    String title = 'Lease agreement',
    String type = 'Contract',
    String referenceLocation = 'file:///docs/lease.pdf',
    String notes = 'Signed copy',
    List<String> tags = const ['legal'],
    DocumentStatus status = DocumentStatus.active,
  }) {
    final now = DateTime(2024, 1, 1, 10, 30);
    return Document(
      id: DocumentId(id),
      workspaceId: 'ws-1',
      title: title,
      type: type,
      referenceLocation: referenceLocation,
      notes: notes,
      tags: tags,
      status: status,
      createdAt: now,
      updatedAt: DateTime(2024, 2, 1, 8),
    );
  }

  group('DocumentMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(document(id: 'document-1', title: 'Lease agreement'));

      expect(row.documentId, 'document-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.title, 'Lease agreement');
      expect(row.type, 'Contract');
      expect(row.referenceLocation, 'file:///docs/lease.pdf');
      expect(row.notes, 'Signed copy');
      expect(row.tags, ['legal']);
    });

    test('maps every DocumentStatus to its enum name', () {
      for (final status in DocumentStatus.values) {
        final row = mapper.toRow(document(status: status));
        expect(row.status, status.name);
      }
    });

    test('always maps deletedAt to null (domain Document is never soft-deleted)',
        () {
      final row = mapper.toRow(document());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode content', () {
      final row = mapper.toRow(document(title: 'Café table ☕ 買い物'));
      expect(row.title, 'Café table ☕ 買い物');
    });
  });

  group('DocumentMapper.toEntity', () {
    DocumentRow row({
      String id = 'document-1',
      String title = 'Lease agreement',
      String status = 'active',
    }) {
      final now = DateTime(2024, 1, 1, 10, 30);
      return DocumentRow(
        documentId: id,
        workspaceId: 'ws-1',
        title: title,
        type: 'Contract',
        referenceLocation: 'file:///docs/lease.pdf',
        notes: 'Signed copy',
        tags: const ['legal'],
        status: status,
        createdAt: now,
        updatedAt: DateTime(2024, 2, 1, 8),
      );
    }

    test('maps all scalar fields', () {
      final entity = mapper.toEntity(row(id: 'document-2', title: 'Warranty card'));

      expect(entity.id, const DocumentId('document-2'));
      expect(entity.workspaceId, 'ws-1');
      expect(entity.title, 'Warranty card');
      expect(entity.referenceLocation, 'file:///docs/lease.pdf');
    });

    test('converts every status column value back to its enum', () {
      for (final status in DocumentStatus.values) {
        final entity = mapper.toEntity(row(status: status.name));
        expect(entity.status, status);
      }
    });

    test('throws DocumentsException for an unrecognized status value', () {
      expect(
        () => mapper.toEntity(row(status: 'not_a_real_status')),
        throwsA(isA<DocumentsException>()),
      );
    });
  });

  group('DocumentMapper round-trip', () {
    test('Document -> DocumentRow -> Document preserves all domain fields', () {
      final original = document(
        id: 'document-rt',
        title: 'Round Trip',
        status: DocumentStatus.active,
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.title, original.title);
      expect(restored.type, original.type);
      expect(restored.referenceLocation, original.referenceLocation);
      expect(restored.notes, original.notes);
      expect(restored.tags, original.tags);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trips an archived document', () {
      final original = document(status: DocumentStatus.archived);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.status, DocumentStatus.archived);
    });
  });
}
