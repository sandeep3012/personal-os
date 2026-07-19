import 'package:feature_finance/src/domain/events/account_created_event.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountCreatedEvent', () {
    final timestamp = DateTime(2024, 6, 15, 10, 30);

    test('holds all construction fields', () {
      final event = AccountCreatedEvent(
        accountId: const AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: 'Savings',
        type: AccountType.savings,
        currency: 'INR',
        timestamp: timestamp,
      );

      expect(event.accountId, const AccountId('acc-1'));
      expect(event.workspaceId, 'ws-1');
      expect(event.name, 'Savings');
      expect(event.type, AccountType.savings);
      expect(event.currency, 'INR');
      expect(event.timestamp, timestamp);
    });

    test('two events with identical fields are not identical objects', () {
      final a = AccountCreatedEvent(
        accountId: const AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: 'Savings',
        type: AccountType.savings,
        currency: 'INR',
        timestamp: timestamp,
      );
      final b = AccountCreatedEvent(
        accountId: const AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: 'Savings',
        type: AccountType.savings,
        currency: 'INR',
        timestamp: timestamp,
      );

      expect(identical(a, b), isFalse);
    });
  });
}
