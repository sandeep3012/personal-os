import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';

final class TransferCreatedEvent extends DomainEvent {
  const TransferCreatedEvent({
    required this.debitTransactionId,
    required this.creditTransactionId,
    required this.workspaceId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.currency,
    required this.date,
    required this.timestamp,
  });

  final TransactionId debitTransactionId;
  final TransactionId creditTransactionId;
  final String workspaceId;
  final AccountId fromAccountId;
  final AccountId toAccountId;
  final Decimal amount;
  final String currency;
  final DateTime date;
  final DateTime timestamp;
}
