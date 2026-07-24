import 'package:application/application.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateDocumentInput {
  const UpdateDocumentInput({
    required this.documentId,
    required this.workspaceId,
    this.title,
    this.type,
    this.referenceLocation,
    this.notes,
    this.tags,
  });

  final DocumentId documentId;
  final String workspaceId;

  /// New title. `null` keeps the existing title.
  final String? title;

  /// New type. `null` keeps the existing type.
  final String? type;

  /// New reference location. `null` keeps the existing reference location.
  final String? referenceLocation;

  /// New notes. `null` keeps the existing notes.
  final String? notes;

  /// New tags. `null` keeps the existing tags.
  final List<String>? tags;
}

/// Updates the mutable, non-status fields of an existing Document.
///
/// `status` is intentionally absent from [UpdateDocumentInput] — status
/// changes go through [ArchiveDocumentUseCase], mirroring
/// `UpdateNoteUseCase` rejecting status as an input.
final class UpdateDocumentUseCase implements AsyncUseCase<UpdateDocumentInput, Document> {
  const UpdateDocumentUseCase({required IDocumentRepository documentRepository})
      : _documentRepository = documentRepository;

  final IDocumentRepository _documentRepository;

  @override
  Future<Result<Document>> execute(UpdateDocumentInput input) async {
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

      final updated = existing.copyWith(
        title: input.title,
        type: input.type,
        referenceLocation: input.referenceLocation,
        notes: input.notes,
        tags: input.tags,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _documentRepository.save(updated);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
