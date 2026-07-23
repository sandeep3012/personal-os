import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';

final class TaskUpdatedEvent extends DomainEvent {
  const TaskUpdatedEvent({
    required this.taskId,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.timestamp,
  });

  final TaskId taskId;
  final String workspaceId;
  final String title;
  final TaskStatus status;
  final DateTime timestamp;
}
