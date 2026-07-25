/// Persistence-layer filter parameters for [GoalDao.query].
///
/// Deliberately distinct from the domain `GoalQuery` value object — the DAO
/// layer must not accept or return domain types. Field values here are raw
/// primitives (`String`) rather than typed domain enums (`GoalStatus`).
/// Translating between the two is a repository-layer concern. Mirrors
/// Finance's `TransactionQueryFilter`.
final class GoalQueryFilter {
  const GoalQueryFilter({
    required this.workspaceId,
    this.status,
    this.nameContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final String? status;
  final String? nameContains;
  final int pageIndex;
  final int pageSize;
}
