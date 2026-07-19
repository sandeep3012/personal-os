import 'package:application/application.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';

final class AccountCreatedEvent extends DomainEvent {
  const AccountCreatedEvent({
    required this.accountId,
    required this.workspaceId,
    required this.name,
    required this.type,
    required this.currency,
    required this.timestamp,
  });

  final AccountId accountId;
  final String workspaceId;
  final String name;
  final AccountType type;
  final String currency;
  final DateTime timestamp;
}
