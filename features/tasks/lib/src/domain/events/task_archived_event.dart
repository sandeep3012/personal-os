import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';

/// Archiving is a distinct, terminal, business-meaningful transition
/// (DOC-032 §11), not an ordinary field update — mirrors why `TransferCreated`
/// is distinct from a plain `TransactionCreated` in Finance.
final class TaskArchivedEvent extends DomainEvent {
  const TaskArchivedEvent({
    required this.taskId,
    required this.workspaceId,
    required this.timestamp,
  });

  final TaskId taskId;
  final String workspaceId;
  final DateTime timestamp;
}
