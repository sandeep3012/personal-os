import 'package:application/application.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';

/// Named as a distinct event (rather than folded into [HabitUpdatedEvent])
/// because DOC-002 names `HabitCompleted` explicitly as a vision-level
/// example event, and completion carries its own meaningful timestamp
/// (DOC-032 §9).
final class HabitCompletedEvent extends DomainEvent {
  const HabitCompletedEvent({
    required this.habitId,
    required this.workspaceId,
    required this.completedAt,
    required this.timestamp,
  });

  final HabitId habitId;
  final String workspaceId;
  final DateTime completedAt;
  final DateTime timestamp;
}
