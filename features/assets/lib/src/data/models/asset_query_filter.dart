/// Persistence-layer filter parameters for [AssetDao.query].
///
/// Deliberately distinct from the domain `AssetQuery` value object — the
/// DAO layer must not accept or return domain types. Field values here are
/// raw primitives (`String`) rather than typed domain enums
/// ([AssetStatus]). Translating between the two is a repository-layer
/// concern. Mirrors Notes' `NoteQueryFilter`.
final class AssetQueryFilter {
  const AssetQueryFilter({
    required this.workspaceId,
    this.status,
    this.nameContains,
    this.categoryContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final String? status;
  final String? nameContains;
  final String? categoryContains;
  final int pageIndex;
  final int pageSize;
}
