/// Persistence-layer filter parameters for [EventDao.query].
///
/// Deliberately distinct from the domain `EventQuery` value object — the
/// DAO layer must not accept or return domain types. Field values here are
/// raw primitives (`String`) rather than typed domain enums
/// ([EventStatus]). Translating between the two is a repository-layer
/// concern. Mirrors Notes' `NoteQueryFilter`.
final class EventQueryFilter {
  const EventQueryFilter({
    required this.workspaceId,
    this.status,
    this.titleContains,
    this.locationContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final String? status;
  final String? titleContains;
  final String? locationContains;
  final int pageIndex;
  final int pageSize;
}
