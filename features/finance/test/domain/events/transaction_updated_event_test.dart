import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/events/transaction_updated_event.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionUpdatedEvent', () {
    final date = DateTime(2024, 6, 15);
    final timestamp = DateTime(2024, 6, 15, 11, 0);

    test('holds all fields including optional ones', () {
      final event = TransactionUpdatedEvent(
        transactionId: const TransactionId('txn-1'),
        workspaceId: 'ws-1',
        accountId: const AccountId('acc-1'),
        type: TransactionType.expense,
        amount: Decimal.parse('750'),
        currency: 'INR',
        categoryId: const CategoryId('cat-travel'),
        payeeName: 'Airline',
        date: date,
        timestamp: timestamp,
      );

      expect(event.transactionId, const TransactionId('txn-1'));
      expect(event.workspaceId, 'ws-1');
      expect(event.accountId, const AccountId('acc-1'));
      expect(event.type, TransactionType.expense);
      expect(event.amount, Decimal.parse('750'));
      expect(event.currency, 'INR');
      expect(event.categoryId, const CategoryId('cat-travel'));
      expect(event.payeeName, 'Airline');
      expect(event.date, date);
      expect(event.timestamp, timestamp);
    });

    test('categoryId and payeeName are null when omitted', () {
      final event = TransactionUpdatedEvent(
        transactionId: const TransactionId('txn-3'),
        workspaceId: 'ws-1',
        accountId: const AccountId('acc-1'),
        type: TransactionType.income,
        amount: Decimal.parse('2000'),
        currency: 'EUR',
        date: date,
        timestamp: timestamp,
      );

      expect(event.categoryId, isNull);
      expect(event.payeeName, isNull);
    });
  });
}
