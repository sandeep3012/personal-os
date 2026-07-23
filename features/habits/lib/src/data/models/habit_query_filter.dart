/// Persistence-layer filter parameters for [HabitDao.query].
///
/// Deliberately distinct from the domain `HabitQuery` value object — the DAO
/// layer must not accept or return domain types. Field values here are raw
/// primitives (`String`) rather than typed domain enums (`HabitStatus`).
/// Translating between the two is a repository-layer concern. Mirrors
/// Finance's `TransactionQueryFilter`.
final class HabitQueryFilter {
  const HabitQueryFilter({
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
