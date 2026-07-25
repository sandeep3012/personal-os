import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:platform_core/platform_core.dart';

final class CreateEventInput {
  const CreateEventInput({
    required this.workspaceId,
    required this.title,
    required this.timeRange,
    this.location = '',
    this.description = '',
  });

  final String workspaceId;
  final String title;
  final EventTimeRange timeRange;
  final String location;
  final String description;
}

/// Creates a new Event and persists it via [IEventRepository].
///
/// New events always start at [EventStatus.active] — mirrors
/// `CreateNoteUseCase` in shape. All validation (title non-empty/length,
/// description length, time-range ordering) is enforced by the [Event]
/// entity constructor and [EventTimeRange] themselves — this use case
/// performs no additional validation.
final class CreateEventUseCase implements AsyncUseCase<CreateEventInput, Event> {
  CreateEventUseCase({
    required IEventRepository eventRepository,
    required IdGenerator idGenerator,
  })  : _eventRepository = eventRepository,
        _idGenerator = idGenerator;

  final IEventRepository _eventRepository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<Event>> execute(CreateEventInput input) async {
    try {
      final now = DateTime.now();
      final event = Event(
        id: EventId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        title: input.title,
        timeRange: input.timeRange,
        location: input.location,
        description: input.description,
        status: EventStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _eventRepository.save(event);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(event);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
