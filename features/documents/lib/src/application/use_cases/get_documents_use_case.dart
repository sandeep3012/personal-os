import 'package:application/application.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetDocumentsInput {
  const GetDocumentsInput({required this.workspaceId});

  final String workspaceId;
}

/// Returns all non-deleted documents in the workspace, regardless of status —
/// filtering by status is [SearchDocumentsUseCase]'s job. Mirrors
/// `GetNotesUseCase` in shape.
final class GetDocumentsUseCase implements AsyncUseCase<GetDocumentsInput, List<Document>> {
  const GetDocumentsUseCase({required IDocumentRepository documentRepository})
      : _documentRepository = documentRepository;

  final IDocumentRepository _documentRepository;

  @override
  Future<Result<List<Document>>> execute(GetDocumentsInput input) async {
    try {
      final result =
          await _documentRepository.findAll(workspaceId: input.workspaceId);
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return Result.success(result.valueOrNull!);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
