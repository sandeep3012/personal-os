import 'package:application/application.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';

final class AccountDeletedEvent extends DomainEvent {
  const AccountDeletedEvent({
    required this.accountId,
    required this.workspaceId,
    required this.timestamp,
  });

  final AccountId accountId;
  final String workspaceId;
  final DateTime timestamp;
}
