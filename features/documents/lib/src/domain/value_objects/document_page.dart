import 'package:feature_documents/src/domain/entities/document.dart';

/// A single page of [Document] results from `SearchDocumentsUseCase`. Mirrors
/// Notes' `NotePage`.
final class DocumentPage {
  const DocumentPage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<Document> items;
  final int totalCount;
  final bool hasNextPage;
}
