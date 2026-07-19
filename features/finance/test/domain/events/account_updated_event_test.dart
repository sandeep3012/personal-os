import 'package:feature_finance/src/domain/events/account_updated_event.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountUpdatedEvent', () {
    final timestamp = DateTime(2024, 6, 15, 10, 30);

    test('holds all construction fields', () {
      final event = AccountUpdatedEvent(
        accountId: const AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: 'Updated Savings',
        isActive: true,
        timestamp: timestamp,
      );

      expect(event.accountId, const AccountId('acc-1'));
      expect(event.workspaceId, 'ws-1');
      expect(event.name, 'Updated Savings');
      expect(event.isActive, isTrue);
      expect(event.timestamp, timestamp);
    });

    test('reflects isActive false when account is deactivated', () {
      final event = AccountUpdatedEvent(
        accountId: const AccountId('acc-2'),
        workspaceId: 'ws-1',
        name: 'Closed Account',
        isActive: false,
        timestamp: timestamp,
      );

      expect(event.isActive, isFalse);
    });
  });
}
