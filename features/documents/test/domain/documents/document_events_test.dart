import 'package:feature_documents/src/domain/documents/document_archived_event.dart';
import 'package:feature_documents/src/domain/documents/document_created_event.dart';
import 'package:feature_documents/src/domain/documents/document_deleted_event.dart';
import 'package:feature_documents/src/domain/documents/document_updated_event.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

void main() {
  final now = DateTime(2026, 1, 1);

  test('DocumentCreatedEvent carries its fields', () {
    final event = DocumentCreatedEvent(
      documentId: const DocumentId('document-1'),
      workspaceId: _ws,
      title: 'Title',
      status: DocumentStatus.active,
      timestamp: now,
    );
    expect(event.documentId, const DocumentId('document-1'));
    expect(event.title, 'Title');
    expect(event.status, DocumentStatus.active);
  });

  test('DocumentUpdatedEvent carries its fields', () {
    final event = DocumentUpdatedEvent(
      documentId: const DocumentId('document-1'),
      workspaceId: _ws,
      title: 'Title',
      status: DocumentStatus.active,
      timestamp: now,
    );
    expect(event.title, 'Title');
  });

  test('DocumentArchivedEvent carries its fields', () {
    final event = DocumentArchivedEvent(
      documentId: const DocumentId('document-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.documentId, const DocumentId('document-1'));
    expect(event.workspaceId, _ws);
  });

  test('DocumentDeletedEvent carries its fields', () {
    final event = DocumentDeletedEvent(
      documentId: const DocumentId('document-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.timestamp, now);
  });
}
