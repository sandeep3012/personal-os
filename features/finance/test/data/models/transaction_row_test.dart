import 'package:feature_finance/src/data/models/transaction_row.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionRow', () {
    test('toMap then fromMap round-trips a plain expense row', () {
      final row = TransactionRow(
        transactionId: 'txn-1',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        amountMinor: 5000,
        currency: 'INR',
        transactionDate: DateTime(2024, 6, 15),
        transactionType: 'expense',
        payee: 'Amazon',
        note: 'Groceries',
        createdAt: DateTime(2024, 6, 15, 9),
        updatedAt: DateTime(2024, 6, 15, 9),
      );

      expect(TransactionRow.fromMap(row.toMap()), row);
    });

    test('round-trips a transfer leg with a transfer_pair_id', () {
      final row = TransactionRow(
        transactionId: 'txn-debit',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        transferPairId: 'txn-credit',
        amountMinor: 100000,
        currency: 'INR',
        transactionDate: DateTime(2024, 6, 15),
        transactionType: 'expense',
        createdAt: DateTime(2024, 6, 15),
        updatedAt: DateTime(2024, 6, 15),
      );

      final roundTripped = TransactionRow.fromMap(row.toMap());
      expect(roundTripped, row);
      expect(roundTripped.transferPairId, 'txn-credit');
    });

    test('round-trips a categorized transaction', () {
      final row = TransactionRow(
        transactionId: 'txn-2',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        categoryId: 'cat-food',
        amountMinor: 2000,
        currency: 'INR',
        transactionDate: DateTime(2024, 6, 15),
        transactionType: 'expense',
        createdAt: DateTime(2024, 6, 15),
        updatedAt: DateTime(2024, 6, 15),
      );

      expect(TransactionRow.fromMap(row.toMap()).categoryId, 'cat-food');
    });

    test('round-trips attachmentIds via JSON encoding', () {
      final row = TransactionRow(
        transactionId: 'txn-3',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        amountMinor: 1000,
        currency: 'INR',
        transactionDate: DateTime(2024, 6, 15),
        transactionType: 'expense',
        attachmentIds: const ['att-1', 'att-2'],
        createdAt: DateTime(2024, 6, 15),
        updatedAt: DateTime(2024, 6, 15),
      );

      final map = row.toMap();
      expect(map[FinanceSchema.transactionAttachmentIds], '["att-1","att-2"]');

      final roundTripped = TransactionRow.fromMap(map);
      expect(roundTripped.attachmentIds, ['att-1', 'att-2']);
    });

    test('empty attachmentIds serializes to null, not an empty JSON array',
        () {
      final row = TransactionRow(
        transactionId: 'txn-4',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        amountMinor: 1000,
        currency: 'INR',
        transactionDate: DateTime(2024, 6, 15),
        transactionType: 'expense',
        createdAt: DateTime(2024, 6, 15),
        updatedAt: DateTime(2024, 6, 15),
      );

      expect(row.toMap()[FinanceSchema.transactionAttachmentIds], isNull);
      expect(TransactionRow.fromMap(row.toMap()).attachmentIds, isEmpty);
    });

    test('round-trips a soft-deleted row', () {
      final row = TransactionRow(
        transactionId: 'txn-5',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        amountMinor: 1000,
        currency: 'INR',
        transactionDate: DateTime(2024, 6, 15),
        transactionType: 'expense',
        createdAt: DateTime(2024, 6, 15),
        updatedAt: DateTime(2024, 6, 16),
        deletedAt: DateTime(2024, 6, 16),
      );

      expect(TransactionRow.fromMap(row.toMap()), row);
    });

    test('nullable fields round-trip as null when absent', () {
      final row = TransactionRow(
        transactionId: 'txn-6',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        amountMinor: 1000,
        currency: 'INR',
        transactionDate: DateTime(2024, 6, 15),
        transactionType: 'income',
        createdAt: DateTime(2024, 6, 15),
        updatedAt: DateTime(2024, 6, 15),
      );

      final roundTripped = TransactionRow.fromMap(row.toMap());
      expect(roundTripped.transferPairId, isNull);
      expect(roundTripped.categoryId, isNull);
      expect(roundTripped.payee, isNull);
      expect(roundTripped.note, isNull);
      expect(roundTripped.deletedAt, isNull);
    });

    test('equality is based on field values, including attachmentIds content',
        () {
      final now = DateTime(2024, 6, 15);
      final a = TransactionRow(
        transactionId: 't',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        amountMinor: 100,
        currency: 'INR',
        transactionDate: now,
        transactionType: 'expense',
        attachmentIds: const ['x'],
        createdAt: now,
        updatedAt: now,
      );
      final b = TransactionRow(
        transactionId: 't',
        workspaceId: 'ws-1',
        accountId: 'acc-1',
        amountMinor: 100,
        currency: 'INR',
        transactionDate: now,
        transactionType: 'expense',
        attachmentIds: const ['x'],
        createdAt: now,
        updatedAt: now,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
