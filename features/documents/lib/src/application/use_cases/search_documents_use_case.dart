import 'package:application/application.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/domain/value_objects/document_page.dart';
import 'package:feature_documents/src/domain/value_objects/document_query.dart';
import 'package:platform_core/platform_core.dart';

/// Executes an [DocumentQuery] and returns a paginated [DocumentPage].
///
/// Delegates directly to [IDocumentRepository.search], which performs
/// SQL-level filtering and pagination via [DocumentDao.query] — orchestration
/// only, no in-memory filtering here. Mirrors `SearchNotesUseCase`.
final class SearchDocumentsUseCase implements AsyncUseCase<DocumentQuery, DocumentPage> {
  const SearchDocumentsUseCase({required IDocumentRepository documentRepository})
      : _documentRepository = documentRepository;

  final IDocumentRepository _documentRepository;

  @override
  Future<Result<DocumentPage>> execute(DocumentQuery input) =>
      _documentRepository.search(input);
}
