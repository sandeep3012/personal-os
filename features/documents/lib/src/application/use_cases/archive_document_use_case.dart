import 'package:application/application.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:platform_core/platform_core.dart';

final class ArchiveDocumentInput {
  const ArchiveDocumentInput({
    required this.documentId,
    required this.workspaceId,
  });

  final DocumentId documentId;
  final String workspaceId;
}

/// Transitions an Document to [DocumentStatus.archived] from
/// [DocumentStatus.active].
///
/// Rejects (via [Document.transitionTo]) if the document is already
/// already archived — mirrors `ArchiveNoteUseCase`'s pattern of failing
/// loudly on an invalid precondition rather than silently accepting a
/// no-op.
final class ArchiveDocumentUseCase implements AsyncUseCase<ArchiveDocumentInput, Document> {
  const ArchiveDocumentUseCase({required IDocumentRepository documentRepository})
      : _documentRepository = documentRepository;

  final IDocumentRepository _documentRepository;

  @override
  Future<Result<Document>> execute(ArchiveDocumentInput input) async {
    try {
      final findResult = await _documentRepository.findById(
        input.documentId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) {
        return Result.failure(findResult.exceptionOrNull!);
      }

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(
          DocumentsException(message: 'Document ${input.documentId} not found'),
        );
      }

      final archived = existing.transitionTo(
        DocumentStatus.archived,
        now: DateTime.now(),
      );

      final saveResult = await _documentRepository.save(archived);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(archived);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
