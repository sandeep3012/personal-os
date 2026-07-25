import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_page.dart';
import 'package:feature_calendar/src/domain/value_objects/event_query.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Event persistence, expressed in domain terms. Mirrors
/// `INoteRepository`.
///
/// Implementations are internal to the Calendar feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-delete is the only supported removal strategy, mirroring Notes.
abstract interface class IEventRepository {
  /// Returns the [Event] with [id] within [workspaceId], or `null` if no
  /// matching, non-deleted event exists.
  FutureResult<Event?> findById(EventId id, {required String workspaceId});

  /// Returns all non-deleted events within [workspaceId], regardless of
  /// status — filtering by status is `SearchEventsUseCase`'s
  /// responsibility, not this method's.
  ///
  /// Returns an empty list when no events exist — never fails for an empty
  /// workspace.
  FutureResult<List<Event>> findAll({required String workspaceId});

  /// Returns all non-deleted events within [workspaceId] whose status
  /// equals [status].
  FutureResult<List<Event>> findByStatus(
    EventStatus status, {
    required String workspaceId,
  });

  /// Executes [query] and returns the matching page of events alongside the
  /// total match count (pre-pagination). Mirrors `INoteRepository.search`.
  FutureResult<EventPage> search(EventQuery query);

  /// Persists [event]. Creates it if it is new; updates it if it already
  /// exists.
  FutureResult<void> save(Event event);

  /// Marks the event identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the event has already been removed.
  /// Soft-delete only; hard deletion is not supported (mirrors Notes).
  FutureResult<void> softDelete(EventId id, {required String workspaceId});
}
