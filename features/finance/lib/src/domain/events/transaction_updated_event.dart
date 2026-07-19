import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';

final class TransactionUpdatedEvent extends DomainEvent {
  const TransactionUpdatedEvent({
    required this.transactionId,
    required this.workspaceId,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.currency,
    this.categoryId,
    this.payeeName,
    required this.date,
    required this.timestamp,
  });

  final TransactionId transactionId;
  final String workspaceId;
  final AccountId accountId;
  final TransactionType type;
  final Decimal amount;
  final String currency;
  final CategoryId? categoryId;
  final String? payeeName;
  final DateTime date;
  final DateTime timestamp;
}
