import 'package:feature_calendar/src/domain/value_objects/event_status.dart';

/// Filter and pagination parameters for `SearchEventsUseCase` (mirrors
/// Notes' `NoteQuery` shape).
///
/// All filter fields are optional — absent fields impose no constraint.
/// [titleContains]/[locationContains] narrow additively (each present field
/// ANDs another condition onto the query) rather than searching across
/// fields with OR semantics — mirrors how Notes applies its filters.
/// Results are paginated via [pageIndex]/[pageSize].
final class EventQuery {
  const EventQuery({
    required this.workspaceId,
    this.status,
    this.titleContains,
    this.locationContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final EventStatus? status;
  final String? titleContains;
  final String? locationContains;
  final int pageIndex;
  final int pageSize;
}
