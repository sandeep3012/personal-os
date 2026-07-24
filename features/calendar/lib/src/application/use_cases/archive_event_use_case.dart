import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:platform_core/platform_core.dart';

final class ArchiveEventInput {
  const ArchiveEventInput({
    required this.eventId,
    required this.workspaceId,
  });

  final EventId eventId;
  final String workspaceId;
}

/// Transitions an Event to [EventStatus.archived] from
/// [EventStatus.active].
///
/// Rejects (via [Event.transitionTo]) if the event is already archived —
/// mirrors `ArchiveNoteUseCase`'s pattern of failing loudly on an invalid
/// precondition rather than silently accepting a no-op.
final class ArchiveEventUseCase implements AsyncUseCase<ArchiveEventInput, Event> {
  const ArchiveEventUseCase({required IEventRepository eventRepository})
      : _eventRepository = eventRepository;

  final IEventRepository _eventRepository;

  @override
  Future<Result<Event>> execute(ArchiveEventInput input) async {
    try {
      final findResult = await _eventRepository.findById(
        input.eventId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) {
        return Result.failure(findResult.exceptionOrNull!);
      }

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(
          CalendarException(message: 'Event ${input.eventId} not found'),
        );
      }

      final archived = existing.transitionTo(
        EventStatus.archived,
        now: DateTime.now(),
      );

      final saveResult = await _eventRepository.save(archived);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(archived);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
