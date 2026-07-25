import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/domain/value_objects/event_page.dart';
import 'package:feature_calendar/src/domain/value_objects/event_query.dart';
import 'package:platform_core/platform_core.dart';

/// Executes an [EventQuery] and returns a paginated [EventPage].
///
/// Delegates directly to [IEventRepository.search], which performs
/// SQL-level filtering and pagination via [EventDao.query] — orchestration
/// only, no in-memory filtering here. Mirrors `SearchNotesUseCase`.
final class SearchEventsUseCase implements AsyncUseCase<EventQuery, EventPage> {
  const SearchEventsUseCase({required IEventRepository eventRepository})
      : _eventRepository = eventRepository;

  final IEventRepository _eventRepository;

  @override
  Future<Result<EventPage>> execute(EventQuery input) =>
      _eventRepository.search(input);
}
