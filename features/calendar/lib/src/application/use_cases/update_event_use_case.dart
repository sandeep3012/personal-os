import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/exceptions/calendar_exception.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateEventInput {
  const UpdateEventInput({
    required this.eventId,
    required this.workspaceId,
    this.title,
    this.timeRange,
    this.location,
    this.description,
  });

  final EventId eventId;
  final String workspaceId;

  /// New title. `null` keeps the existing title.
  final String? title;

  /// New time range. `null` keeps the existing time range.
  final EventTimeRange? timeRange;

  /// New location. `null` keeps the existing location.
  final String? location;

  /// New description. `null` keeps the existing description.
  final String? description;
}

/// Updates the mutable, non-status fields of an existing Event.
///
/// `status` is intentionally absent from [UpdateEventInput] — status
/// changes go through [ArchiveEventUseCase], mirroring `UpdateNoteUseCase`
/// rejecting status as an input.
final class UpdateEventUseCase implements AsyncUseCase<UpdateEventInput, Event> {
  const UpdateEventUseCase({required IEventRepository eventRepository})
      : _eventRepository = eventRepository;

  final IEventRepository _eventRepository;

  @override
  Future<Result<Event>> execute(UpdateEventInput input) async {
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

      final updated = existing.copyWith(
        title: input.title,
        timeRange: input.timeRange,
        location: input.location,
        description: input.description,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _eventRepository.save(updated);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
