import 'package:application/application.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';

final class GoalDeletedEvent extends DomainEvent {
  const GoalDeletedEvent({
    required this.goalId,
    required this.workspaceId,
    required this.timestamp,
  });

  final GoalId goalId;
  final String workspaceId;
  final DateTime timestamp;
}
