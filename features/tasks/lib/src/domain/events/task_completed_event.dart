import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';

/// Named as a distinct event (rather than folded into [TaskUpdatedEvent])
/// because DOC-002 names `TaskCompleted` explicitly as a vision-level
/// example event, and completion carries its own meaningful timestamp
/// (DOC-032 §9).
final class TaskCompletedEvent extends DomainEvent {
  const TaskCompletedEvent({
    required this.taskId,
    required this.workspaceId,
    required this.completedAt,
    required this.timestamp,
  });

  final TaskId taskId;
  final String workspaceId;
  final DateTime completedAt;
  final DateTime timestamp;
}
