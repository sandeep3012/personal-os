import 'package:application/application.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';

/// Named as a distinct event (rather than folded into [GoalUpdatedEvent])
/// because DOC-002 names `GoalCompleted` explicitly as a vision-level
/// example event, and completion carries its own meaningful timestamp
/// (DOC-032 §9).
final class GoalCompletedEvent extends DomainEvent {
  const GoalCompletedEvent({
    required this.goalId,
    required this.workspaceId,
    required this.completedAt,
    required this.timestamp,
  });

  final GoalId goalId;
  final String workspaceId;
  final DateTime completedAt;
  final DateTime timestamp;
}
