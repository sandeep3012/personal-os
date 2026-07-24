import 'package:application/application.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';

final class DocumentUpdatedEvent extends DomainEvent {
  const DocumentUpdatedEvent({
    required this.documentId,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.timestamp,
  });

  final DocumentId documentId;
  final String workspaceId;
  final String title;
  final DocumentStatus status;
  final DateTime timestamp;
}
