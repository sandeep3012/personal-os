import 'package:feature_documents/src/domain/value_objects/document_status.dart';

/// Filter and pagination parameters for `SearchDocumentsUseCase` (mirrors
/// Notes' `NoteQuery` shape).
///
/// All filter fields are optional — absent fields impose no constraint.
/// [titleContains]/[typeContains]/[tagContains] narrow additively (each
/// present field ANDs another condition onto the query) rather than
/// searching across fields with OR semantics — mirrors how Notes applies
/// its filters. Results are paginated via [pageIndex]/[pageSize].
final class DocumentQuery {
  const DocumentQuery({
    required this.workspaceId,
    this.status,
    this.titleContains,
    this.typeContains,
    this.tagContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final DocumentStatus? status;
  final String? titleContains;
  final String? typeContains;
  final String? tagContains;
  final int pageIndex;
  final int pageSize;
}
