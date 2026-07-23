import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';

final class TaskDeletedEvent extends DomainEvent {
  const TaskDeletedEvent({
    required this.taskId,
    required this.workspaceId,
    required this.timestamp,
  });

  final TaskId taskId;
  final String workspaceId;
  final DateTime timestamp;
}
