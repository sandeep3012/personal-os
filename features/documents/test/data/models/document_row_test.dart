import 'package:feature_documents/src/data/models/document_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentRow toMap/fromMap round-trip', () {
    test('round-trips all fields including nullable deletedAt', () {
      final row = DocumentRow(
        documentId: 'document-1',
        workspaceId: 'ws-1',
        title: 'Lease agreement',
        type: 'Contract',
        referenceLocation: 'file:///docs/lease.pdf',
        notes: 'Signed copy',
        tags: const ['legal', 'home'],
        status: 'active',
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 3, 8),
        deletedAt: null,
      );

      final restored = DocumentRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips a soft-deleted row', () {
      final row = DocumentRow(
        documentId: 'document-2',
        workspaceId: 'ws-1',
        title: 'Archived document',
        type: 'Receipt',
        referenceLocation: '',
        status: 'archived',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 6),
        deletedAt: DateTime(2026, 1, 7),
      );

      final restored = DocumentRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips minimal fields (no notes, no tags)', () {
      final row = DocumentRow(
        documentId: 'document-3',
        workspaceId: 'ws-1',
        title: 'Minimal',
        type: 'Misc',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = DocumentRow.fromMap(row.toMap());

      expect(restored, row);
      expect(restored.notes, '');
      expect(restored.tags, isEmpty);
      expect(restored.deletedAt, isNull);
    });

    test('decodes a null notes/tags column back to empty', () {
      final restored = DocumentRow.fromMap({
        'document_id': 'document-5',
        'workspace_id': 'ws-1',
        'title': 'No extras',
        'type': 'Misc',
        'reference_location': null,
        'notes': null,
        'tags': null,
        'status': 'active',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime(2026, 1, 1).toIso8601String(),
        'deleted_at': null,
      });

      expect(restored.notes, '');
      expect(restored.referenceLocation, '');
      expect(restored.tags, isEmpty);
    });
  });
}
