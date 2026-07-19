import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/events/transfer_created_event.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransferCreatedEvent', () {
    test('holds all construction fields', () {
      final date = DateTime(2024, 6, 15);
      final timestamp = DateTime(2024, 6, 15, 14, 0);

      final event = TransferCreatedEvent(
        debitTransactionId: const TransactionId('txn-debit'),
        creditTransactionId: const TransactionId('txn-credit'),
        workspaceId: 'ws-1',
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        amount: Decimal.parse('1000'),
        currency: 'INR',
        date: date,
        timestamp: timestamp,
      );

      expect(event.debitTransactionId, const TransactionId('txn-debit'));
      expect(event.creditTransactionId, const TransactionId('txn-credit'));
      expect(event.workspaceId, 'ws-1');
      expect(event.fromAccountId, const AccountId('acc-from'));
      expect(event.toAccountId, const AccountId('acc-to'));
      expect(event.amount, Decimal.parse('1000'));
      expect(event.currency, 'INR');
      expect(event.date, date);
      expect(event.timestamp, timestamp);
    });

    test('debit and credit transaction IDs are distinct', () {
      final timestamp = DateTime(2024, 6, 15, 14, 0);

      final event = TransferCreatedEvent(
        debitTransactionId: const TransactionId('txn-debit'),
        creditTransactionId: const TransactionId('txn-credit'),
        workspaceId: 'ws-1',
        fromAccountId: const AccountId('acc-a'),
        toAccountId: const AccountId('acc-b'),
        amount: Decimal.parse('500'),
        currency: 'USD',
        date: timestamp,
        timestamp: timestamp,
      );

      expect(event.debitTransactionId, isNot(event.creditTransactionId));
    });
  });
}
