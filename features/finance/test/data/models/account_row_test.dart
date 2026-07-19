import 'package:feature_finance/src/data/models/account_row.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountRow', () {
    test('toMap then fromMap round-trips to an equal row', () {
      final row = AccountRow(
        accountId: 'acc-1',
        workspaceId: 'ws-1',
        name: 'Savings',
        accountType: 'savings',
        currency: 'INR',
        openingBalanceMinor: 150000,
        isActive: true,
        createdAt: DateTime(2024, 1, 1, 10, 30),
        updatedAt: DateTime(2024, 2, 1, 8, 0),
        deletedAt: null,
      );

      final roundTripped = AccountRow.fromMap(row.toMap());

      expect(roundTripped, row);
    });

    test('round-trips a soft-deleted row', () {
      final row = AccountRow(
        accountId: 'acc-2',
        workspaceId: 'ws-1',
        name: 'Closed',
        accountType: 'checking',
        currency: 'USD',
        openingBalanceMinor: 0,
        isActive: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 3, 1),
        deletedAt: DateTime(2024, 3, 1),
      );

      expect(AccountRow.fromMap(row.toMap()), row);
    });

    test('toMap encodes isActive as an integer 0/1', () {
      final activeRow = AccountRow(
        accountId: 'a',
        workspaceId: 'ws-1',
        name: 'n',
        accountType: 'cash',
        currency: 'INR',
        openingBalanceMinor: 0,
        isActive: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final inactiveRow = AccountRow(
        accountId: 'a',
        workspaceId: 'ws-1',
        name: 'n',
        accountType: 'cash',
        currency: 'INR',
        openingBalanceMinor: 0,
        isActive: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      expect(activeRow.toMap()[FinanceSchema.accountIsActive], 1);
      expect(inactiveRow.toMap()[FinanceSchema.accountIsActive], 0);
    });

    test('toMap encodes dates as ISO 8601 strings', () {
      final row = AccountRow(
        accountId: 'a',
        workspaceId: 'ws-1',
        name: 'n',
        accountType: 'cash',
        currency: 'INR',
        openingBalanceMinor: 0,
        isActive: true,
        createdAt: DateTime(2024, 6, 15, 10, 30),
        updatedAt: DateTime(2024, 6, 15, 10, 30),
      );

      expect(
        row.toMap()[FinanceSchema.accountCreatedAt],
        DateTime(2024, 6, 15, 10, 30).toIso8601String(),
      );
    });

    test('toMap yields null for deletedAt when the row is not soft-deleted',
        () {
      final row = AccountRow(
        accountId: 'a',
        workspaceId: 'ws-1',
        name: 'n',
        accountType: 'cash',
        currency: 'INR',
        openingBalanceMinor: 0,
        isActive: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      expect(row.toMap()[FinanceSchema.accountDeletedAt], isNull);
    });

    test('equality is based on field values, not identity', () {
      final now = DateTime(2024);
      final a = AccountRow(
        accountId: 'a',
        workspaceId: 'ws-1',
        name: 'n',
        accountType: 'cash',
        currency: 'INR',
        openingBalanceMinor: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      final b = AccountRow(
        accountId: 'a',
        workspaceId: 'ws-1',
        name: 'n',
        accountType: 'cash',
        currency: 'INR',
        openingBalanceMinor: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(identical(a, b), isFalse);
    });
  });
}
