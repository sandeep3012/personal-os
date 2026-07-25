import 'package:application/application.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetDocumentInput {
  const GetDocumentInput({required this.documentId, required this.workspaceId});

  final DocumentId documentId;
  final String workspaceId;
}

/// Returns a single Document by id. Mirrors `GetNoteUseCase`.
final class GetDocumentUseCase implements AsyncUseCase<GetDocumentInput, Document> {
  const GetDocumentUseCase({required IDocumentRepository documentRepository})
      : _documentRepository = documentRepository;

  final IDocumentRepository _documentRepository;

  @override
  Future<Result<Document>> execute(GetDocumentInput input) async {
    try {
      final result = await _documentRepository.findById(
        input.documentId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final document = result.valueOrNull;
      if (document == null) {
        return Result.failure(
          DocumentsException(message: 'Document ${input.documentId} not found'),
        );
      }

      return Result.success(document);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
