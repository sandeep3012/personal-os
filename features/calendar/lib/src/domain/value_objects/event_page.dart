import 'package:feature_calendar/src/domain/entities/event.dart';

/// A single page of [Event] results from `SearchEventsUseCase`. Mirrors
/// Notes' `NotePage`.
final class EventPage {
  const EventPage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<Event> items;
  final int totalCount;
  final bool hasNextPage;
}
