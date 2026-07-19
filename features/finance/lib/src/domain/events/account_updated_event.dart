import 'package:application/application.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';

final class AccountUpdatedEvent extends DomainEvent {
  const AccountUpdatedEvent({
    required this.accountId,
    required this.workspaceId,
    required this.name,
    required this.isActive,
    required this.timestamp,
  });

  final AccountId accountId;
  final String workspaceId;
  final String name;
  final bool isActive;
  final DateTime timestamp;
}
