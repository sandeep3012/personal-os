import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteEventInput {
  const DeleteEventInput({
    required this.eventId,
    required this.workspaceId,
  });

  final EventId eventId;
  final String workspaceId;
}

/// Soft-deletes an Event.
///
/// No precondition beyond existence — mirrors `DeleteNoteUseCase`; Event is
/// a standalone aggregate with no cross-entity precondition.
final class DeleteEventUseCase implements AsyncUseCase<DeleteEventInput, void> {
  const DeleteEventUseCase({required IEventRepository eventRepository})
      : _eventRepository = eventRepository;

  final IEventRepository _eventRepository;

  @override
  Future<Result<void>> execute(DeleteEventInput input) async {
    try {
      final deleteResult = await _eventRepository.softDelete(
        input.eventId,
        workspaceId: input.workspaceId,
      );
      if (deleteResult.isFailure) {
        return Result.failure(deleteResult.exceptionOrNull!);
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
