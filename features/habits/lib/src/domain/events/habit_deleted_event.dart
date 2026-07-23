import 'package:application/application.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';

final class HabitDeletedEvent extends DomainEvent {
  const HabitDeletedEvent({
    required this.habitId,
    required this.workspaceId,
    required this.timestamp,
  });

  final HabitId habitId;
  final String workspaceId;
  final DateTime timestamp;
}
