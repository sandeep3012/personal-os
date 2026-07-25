/// Persistence-layer filter parameters for [NoteDao.query].
///
/// Deliberately distinct from the domain `NoteQuery` value object — the DAO
/// layer must not accept or return domain types. Field values here are raw
/// primitives (`String`) rather than typed domain enums (`NoteStatus`).
/// Translating between the two is a repository-layer concern. Mirrors
/// Goals' `GoalQueryFilter`.
final class NoteQueryFilter {
  const NoteQueryFilter({
    required this.workspaceId,
    this.status,
    this.titleContains,
    this.contentContains,
    this.tagContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final String? status;
  final String? titleContains;
  final String? contentContains;
  final String? tagContains;
  final int pageIndex;
  final int pageSize;
}
