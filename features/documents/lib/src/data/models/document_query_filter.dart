/// Persistence-layer filter parameters for [DocumentDao.query].
///
/// Deliberately distinct from the domain `DocumentQuery` value object — the
/// DAO layer must not accept or return domain types. Field values here are
/// raw primitives (`String`) rather than typed domain enums
/// ([DocumentStatus]). Translating between the two is a repository-layer
/// concern. Mirrors Notes' `NoteQueryFilter`.
final class DocumentQueryFilter {
  const DocumentQueryFilter({
    required this.workspaceId,
    this.status,
    this.titleContains,
    this.typeContains,
    this.tagContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final String? status;
  final String? titleContains;
  final String? typeContains;
  final String? tagContains;
  final int pageIndex;
  final int pageSize;
}
