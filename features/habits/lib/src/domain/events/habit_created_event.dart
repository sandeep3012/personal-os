import 'package:application/application.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';

final class HabitCreatedEvent extends DomainEvent {
  const HabitCreatedEvent({
    required this.habitId,
    required this.workspaceId,
    required this.name,
    required this.status,
    required this.timestamp,
  });

  final HabitId habitId;
  final String workspaceId;
  final String name;
  final HabitStatus status;
  final DateTime timestamp;
}
