import 'package:application/application.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:platform_core/platform_core.dart';

final class CreateDocumentInput {
  const CreateDocumentInput({
    required this.workspaceId,
    required this.title,
    required this.type,
    this.referenceLocation = '',
    this.notes = '',
    this.tags = const [],
  });

  final String workspaceId;
  final String title;
  final String type;
  final String referenceLocation;
  final String notes;
  final List<String> tags;
}

/// Creates a new Document and persists it via [IDocumentRepository].
///
/// New documents always start at [DocumentStatus.active] — mirrors
/// `CreateNoteUseCase` in shape. All validation (title/type non-empty
/// and length, referenceLocation/notes length, tag normalization) is
/// enforced by the [Document] entity constructor itself — this use case
/// performs no additional validation.
final class CreateDocumentUseCase implements AsyncUseCase<CreateDocumentInput, Document> {
  CreateDocumentUseCase({
    required IDocumentRepository documentRepository,
    required IdGenerator idGenerator,
  })  : _documentRepository = documentRepository,
        _idGenerator = idGenerator;

  final IDocumentRepository _documentRepository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<Document>> execute(CreateDocumentInput input) async {
    try {
      final now = DateTime.now();
      final document = Document(
        id: DocumentId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        title: input.title,
        type: input.type,
        referenceLocation: input.referenceLocation,
        notes: input.notes,
        tags: input.tags,
        status: DocumentStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _documentRepository.save(document);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(document);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
