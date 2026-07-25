import 'package:application/application.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';

final class GoalCreatedEvent extends DomainEvent {
  const GoalCreatedEvent({
    required this.goalId,
    required this.workspaceId,
    required this.name,
    required this.status,
    required this.timestamp,
  });

  final GoalId goalId;
  final String workspaceId;
  final String name;
  final GoalStatus status;
  final DateTime timestamp;
}
