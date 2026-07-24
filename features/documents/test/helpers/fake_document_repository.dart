import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_page.dart';
import 'package:feature_documents/src/domain/value_objects/document_query.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [IDocumentRepository] for use-case unit tests. Mirrors Notes'
/// `FakeNoteRepository`.
final class FakeDocumentRepository implements IDocumentRepository {
  final List<Document> _store = [];

  List<Document> get store => List.unmodifiable(_store);

  void seed(List<Document> documents) {
    _store.clear();
    _store.addAll(documents);
  }

  @override
  FutureResult<Document?> findById(DocumentId id, {required String workspaceId}) async =>
      Result.success(_store.where((e) => e.id == id).firstOrNull);

  @override
  FutureResult<List<Document>> findAll({required String workspaceId}) async =>
      Result.success(List.unmodifiable(_store));

  @override
  FutureResult<List<Document>> findByStatus(
    DocumentStatus status, {
    required String workspaceId,
  }) async =>
      Result.success(
        List.unmodifiable(_store.where((e) => e.status == status).toList()),
      );

  @override
  FutureResult<DocumentPage> search(DocumentQuery query) async {
    var filtered = _store.where((e) => e.workspaceId == query.workspaceId);
    if (query.status != null) {
      filtered = filtered.where((e) => e.status == query.status);
    }
    if (query.titleContains != null && query.titleContains!.isNotEmpty) {
      filtered = filtered.where(
        (e) => e.title.toLowerCase().contains(query.titleContains!.toLowerCase()),
      );
    }
    if (query.typeContains != null && query.typeContains!.isNotEmpty) {
      filtered = filtered.where(
        (e) => e.type.toLowerCase().contains(query.typeContains!.toLowerCase()),
      );
    }
    if (query.tagContains != null && query.tagContains!.isNotEmpty) {
      filtered = filtered.where(
        (e) => e.tags.any(
          (tag) => tag.toLowerCase().contains(query.tagContains!.toLowerCase()),
        ),
      );
    }
    final all = filtered.toList();
    final start = query.pageIndex * query.pageSize;
    final end = (start + query.pageSize).clamp(0, all.length);
    final items = start >= all.length ? <Document>[] : all.sublist(start, end);

    return Result.success(DocumentPage(
      items: items,
      totalCount: all.length,
      hasNextPage: end < all.length,
    ));
  }

  @override
  FutureResult<void> save(Document document) async {
    _store.removeWhere((e) => e.id == document.id);
    _store.add(document);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(DocumentId id, {required String workspaceId}) async {
    _store.removeWhere((e) => e.id == id);
    return const Result.success(null);
  }
}
