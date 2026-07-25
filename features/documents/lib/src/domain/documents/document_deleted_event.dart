import 'package:application/application.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';

final class DocumentDeletedEvent extends DomainEvent {
  const DocumentDeletedEvent({
    required this.documentId,
    required this.workspaceId,
    required this.timestamp,
  });

  final DocumentId documentId;
  final String workspaceId;
  final DateTime timestamp;
}
