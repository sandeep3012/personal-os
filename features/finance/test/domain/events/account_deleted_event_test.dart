import 'package:feature_finance/src/domain/events/account_deleted_event.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountDeletedEvent', () {
    test('holds all construction fields', () {
      final timestamp = DateTime(2024, 6, 15, 10, 30);

      final event = AccountDeletedEvent(
        accountId: const AccountId('acc-1'),
        workspaceId: 'ws-1',
        timestamp: timestamp,
      );

      expect(event.accountId, const AccountId('acc-1'));
      expect(event.workspaceId, 'ws-1');
      expect(event.timestamp, timestamp);
    });
  });
}
