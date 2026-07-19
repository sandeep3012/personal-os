import 'package:application/application.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';

final class TransactionDeletedEvent extends DomainEvent {
  const TransactionDeletedEvent({
    required this.transactionId,
    required this.workspaceId,
    required this.accountId,
    required this.type,
    required this.timestamp,
  });

  final TransactionId transactionId;
  final String workspaceId;
  final AccountId accountId;
  final TransactionType type;
  final DateTime timestamp;
}
