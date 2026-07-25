import 'package:application/application.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteDocumentInput {
  const DeleteDocumentInput({
    required this.documentId,
    required this.workspaceId,
  });

  final DocumentId documentId;
  final String workspaceId;
}

/// Soft-deletes an Document.
///
/// No precondition beyond existence — mirrors `DeleteNoteUseCase`; Document is
/// a standalone aggregate with no cross-entity precondition.
final class DeleteDocumentUseCase implements AsyncUseCase<DeleteDocumentInput, void> {
  const DeleteDocumentUseCase({required IDocumentRepository documentRepository})
      : _documentRepository = documentRepository;

  final IDocumentRepository _documentRepository;

  @override
  Future<Result<void>> execute(DeleteDocumentInput input) async {
    try {
      final deleteResult = await _documentRepository.softDelete(
        input.documentId,
        workspaceId: input.workspaceId,
      );
      if (deleteResult.isFailure) {
        return Result.failure(deleteResult.exceptionOrNull!);
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
