import 'package:application/application.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';

/// Archiving is a distinct, terminal, business-meaningful transition
/// (DOC-032 §11), not an ordinary field update — mirrors why `TransferCreated`
/// is distinct from a plain `TransactionCreated` in Finance.
final class HabitArchivedEvent extends DomainEvent {
  const HabitArchivedEvent({
    required this.habitId,
    required this.workspaceId,
    required this.timestamp,
  });

  final HabitId habitId;
  final String workspaceId;
  final DateTime timestamp;
}
