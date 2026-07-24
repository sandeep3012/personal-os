import 'package:application/application.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetEventsInput {
  const GetEventsInput({required this.workspaceId});

  final String workspaceId;
}

/// Returns all non-deleted events in the workspace, regardless of status —
/// filtering by status is [SearchEventsUseCase]'s job. Mirrors
/// `GetNotesUseCase` in shape.
final class GetEventsUseCase implements AsyncUseCase<GetEventsInput, List<Event>> {
  const GetEventsUseCase({required IEventRepository eventRepository})
      : _eventRepository = eventRepository;

  final IEventRepository _eventRepository;

  @override
  Future<Result<List<Event>>> execute(GetEventsInput input) async {
    try {
      final result =
          await _eventRepository.findAll(workspaceId: input.workspaceId);
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return Result.success(result.valueOrNull!);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
