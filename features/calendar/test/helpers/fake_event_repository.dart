import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_page.dart';
import 'package:feature_calendar/src/domain/value_objects/event_query.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [IEventRepository] for use-case unit tests. Mirrors Notes'
/// `FakeNoteRepository`.
final class FakeEventRepository implements IEventRepository {
  final List<Event> _store = [];

  List<Event> get store => List.unmodifiable(_store);

  void seed(List<Event> events) {
    _store.clear();
    _store.addAll(events);
  }

  @override
  FutureResult<Event?> findById(EventId id, {required String workspaceId}) async =>
      Result.success(_store.where((e) => e.id == id).firstOrNull);

  @override
  FutureResult<List<Event>> findAll({required String workspaceId}) async =>
      Result.success(List.unmodifiable(_store));

  @override
  FutureResult<List<Event>> findByStatus(
    EventStatus status, {
    required String workspaceId,
  }) async =>
      Result.success(
        List.unmodifiable(_store.where((e) => e.status == status).toList()),
      );

  @override
  FutureResult<EventPage> search(EventQuery query) async {
    var filtered = _store.where((e) => e.workspaceId == query.workspaceId);
    if (query.status != null) {
      filtered = filtered.where((e) => e.status == query.status);
    }
    if (query.titleContains != null && query.titleContains!.isNotEmpty) {
      filtered = filtered.where(
        (e) => e.title.toLowerCase().contains(query.titleContains!.toLowerCase()),
      );
    }
    if (query.locationContains != null && query.locationContains!.isNotEmpty) {
      filtered = filtered.where(
        (e) =>
            e.location.toLowerCase().contains(query.locationContains!.toLowerCase()),
      );
    }
    final all = filtered.toList();
    final start = query.pageIndex * query.pageSize;
    final end = (start + query.pageSize).clamp(0, all.length);
    final items = start >= all.length ? <Event>[] : all.sublist(start, end);

    return Result.success(EventPage(
      items: items,
      totalCount: all.length,
      hasNextPage: end < all.length,
    ));
  }

  @override
  FutureResult<void> save(Event event) async {
    _store.removeWhere((e) => e.id == event.id);
    _store.add(event);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(EventId id, {required String workspaceId}) async {
    _store.removeWhere((e) => e.id == id);
    return const Result.success(null);
  }
}
