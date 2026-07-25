import 'package:application/application.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';

/// Archiving is a distinct, terminal, business-meaningful transition
/// (DOC-032 §11), not an ordinary field update — mirrors why `TransferCreated`
/// is distinct from a plain `TransactionCreated` in Finance.
final class GoalArchivedEvent extends DomainEvent {
  const GoalArchivedEvent({
    required this.goalId,
    required this.workspaceId,
    required this.timestamp,
  });

  final GoalId goalId;
  final String workspaceId;
  final DateTime timestamp;
}
