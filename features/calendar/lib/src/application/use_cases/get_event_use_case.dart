import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetEventInput {
  const GetEventInput({required this.eventId, required this.workspaceId});

  final EventId eventId;
  final String workspaceId;
}

/// Returns a single Event by id. Mirrors `GetNoteUseCase`.
final class GetEventUseCase implements AsyncUseCase<GetEventInput, Event> {
  const GetEventUseCase({required IEventRepository eventRepository})
      : _eventRepository = eventRepository;

  final IEventRepository _eventRepository;

  @override
  Future<Result<Event>> execute(GetEventInput input) async {
    try {
      final result = await _eventRepository.findById(
        input.eventId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final event = result.valueOrNull;
      if (event == null) {
        return Result.failure(
          CalendarException(message: 'Event ${input.eventId} not found'),
        );
      }

      return Result.success(event);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
