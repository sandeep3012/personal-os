import 'package:feature_finance/src/domain/events/transaction_deleted_event.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionDeletedEvent', () {
    test('holds all construction fields', () {
      final timestamp = DateTime(2024, 6, 15, 12, 0);

      final event = TransactionDeletedEvent(
        transactionId: const TransactionId('txn-1'),
        workspaceId: 'ws-1',
        accountId: const AccountId('acc-1'),
        type: TransactionType.expense,
        timestamp: timestamp,
      );

      expect(event.transactionId, const TransactionId('txn-1'));
      expect(event.workspaceId, 'ws-1');
      expect(event.accountId, const AccountId('acc-1'));
      expect(event.type, TransactionType.expense);
      expect(event.timestamp, timestamp);
    });
  });
}
