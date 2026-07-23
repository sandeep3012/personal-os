/// Persistence-layer filter parameters for [TaskDao.query].
///
/// Deliberately distinct from the domain `TaskQuery` value object — the DAO
/// layer must not accept or return domain types. Field values here are raw
/// primitives (`String`) rather than typed domain enums (`TaskStatus`).
/// Translating between the two is a repository-layer concern. Mirrors
/// Finance's `TransactionQueryFilter`.
final class TaskQueryFilter {
  const TaskQueryFilter({
    required this.workspaceId,
    this.status,
    this.titleContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final String? status;
  final String? titleContains;
  final int pageIndex;
  final int pageSize;
}
