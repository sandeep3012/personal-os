import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/data/mappers/transaction_mapper.dart';
import 'package:feature_finance/src/data/models/transaction_row.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TransactionMapper();

  Transaction transaction({
    String id = 'txn-1',
    String workspaceId = 'ws-1',
    String accountId = 'acc-1',
    TransactionType type = TransactionType.expense,
    String amount = '100',
    String currency = 'INR',
    CategoryId? categoryId,
    Payee? payee,
    String? note,
    TransactionId? transferCounterpartId,
    List<String> attachmentIds = const [],
    DateTime? date,
  }) {
    final cc = CurrencyCode(currency);
    final d = date ?? DateTime(2024, 6, 15);
    return Transaction(
      id: TransactionId(id),
      workspaceId: workspaceId,
      accountId: AccountId(accountId),
      type: type,
      amount: Money(amount: Decimal.parse(amount), currency: cc),
      categoryId: categoryId,
      payee: payee,
      note: note,
      date: TransactionDate(d),
      transferCounterpartId: transferCounterpartId,
      attachmentIds: attachmentIds,
      createdAt: DateTime(2024, 6, 15, 9),
      updatedAt: DateTime(2024, 6, 16, 11),
    );
  }

  group('TransactionMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(transaction(id: 'txn-1', accountId: 'acc-1'));

      expect(row.transactionId, 'txn-1');
      expect(row.accountId, 'acc-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.transactionType, 'expense');
      expect(row.currency, 'INR');
    });

    test('converts Money to minor units via the centralized converter', () {
      final row = mapper.toRow(transaction(amount: '500.25'));
      expect(row.amountMinor, 50025);
    });

    test('converts a very large amount without precision loss', () {
      final row = mapper.toRow(transaction(amount: '999999999999.99'));
      expect(row.amountMinor, 99999999999999);
    });

    test('maps categoryId to a nullable String', () {
      final withCategory =
          mapper.toRow(transaction(categoryId: const CategoryId('cat-food')));
      final withoutCategory = mapper.toRow(transaction());

      expect(withCategory.categoryId, 'cat-food');
      expect(withoutCategory.categoryId, isNull);
    });

    test('maps payee to a nullable String', () {
      final withPayee = mapper.toRow(transaction(payee: Payee('Amazon')));
      final withoutPayee = mapper.toRow(transaction());

      expect(withPayee.payee, 'Amazon');
      expect(withoutPayee.payee, isNull);
    });

    test('maps transferCounterpartId to transferPairId', () {
      final row = mapper.toRow(transaction(
        type: TransactionType.transfer,
        transferCounterpartId: const TransactionId('txn-counterpart'),
      ));
      expect(row.transferPairId, 'txn-counterpart');
    });

    test('maps note when present, null when absent', () {
      final withNote = mapper.toRow(transaction(note: 'Monthly rent'));
      final withoutNote = mapper.toRow(transaction());

      expect(withNote.note, 'Monthly rent');
      expect(withoutNote.note, isNull);
    });

    test('maps attachmentIds through unchanged', () {
      final row = mapper.toRow(
        transaction(attachmentIds: const ['att-1', 'att-2']),
      );
      expect(row.attachmentIds, ['att-1', 'att-2']);
    });

    test('maps an empty attachmentIds list as an empty list, not null', () {
      final row = mapper.toRow(transaction());
      expect(row.attachmentIds, isEmpty);
    });

    test('always maps deletedAt to null (domain Transaction is never '
        'soft-deleted)', () {
      final row = mapper.toRow(transaction());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode payee and note text', () {
      final row = mapper.toRow(transaction(
        payee: Payee('Café Périphérique 咖啡店'),
        note: 'Résumé — 备注 🎉',
      ));
      expect(row.payee, 'Café Périphérique 咖啡店');
      expect(row.note, 'Résumé — 备注 🎉');
    });

    test('maps every TransactionType to its enum name', () {
      for (final type in TransactionType.values) {
        final txn = type == TransactionType.transfer
            ? transaction(
                type: type,
                transferCounterpartId: const TransactionId('pair'),
              )
            : transaction(type: type);
        expect(mapper.toRow(txn).transactionType, type.name);
      }
    });

    test('preserves createdAt and updatedAt exactly', () {
      final row = mapper.toRow(transaction());
      expect(row.createdAt, DateTime(2024, 6, 15, 9));
      expect(row.updatedAt, DateTime(2024, 6, 16, 11));
    });
  });

  group('TransactionMapper.toEntity', () {
    TransactionRow row({
      String id = 'txn-1',
      String workspaceId = 'ws-1',
      String accountId = 'acc-1',
      String? transferPairId,
      String? categoryId,
      int amountMinor = 10000,
      String currency = 'INR',
      String type = 'expense',
      String? payee,
      String? note,
      List<String> attachmentIds = const [],
      DateTime? date,
      DateTime? deletedAt,
    }) {
      final d = date ?? DateTime(2024, 6, 15);
      return TransactionRow(
        transactionId: id,
        workspaceId: workspaceId,
        accountId: accountId,
        transferPairId: transferPairId,
        categoryId: categoryId,
        amountMinor: amountMinor,
        currency: currency,
        transactionDate: d,
        transactionType: type,
        payee: payee,
        note: note,
        attachmentIds: attachmentIds,
        createdAt: DateTime(2024, 6, 15, 9),
        updatedAt: DateTime(2024, 6, 16, 11),
        deletedAt: deletedAt,
      );
    }

    test('maps all scalar fields', () {
      final txn = mapper.toEntity(row(id: 'txn-2', accountId: 'acc-2'));

      expect(txn.id, const TransactionId('txn-2'));
      expect(txn.accountId, const AccountId('acc-2'));
      expect(txn.workspaceId, 'ws-1');
      expect(txn.type, TransactionType.expense);
    });

    test('converts minor units back to Decimal Money', () {
      final txn = mapper.toEntity(row(amountMinor: 50025));
      expect(txn.amount.amount, Decimal.parse('500.25'));
      expect(txn.amount.currency.value, 'INR');
    });

    test('converts a very large minor-unit value without precision loss', () {
      final txn = mapper.toEntity(row(amountMinor: 99999999999999));
      expect(txn.amount.amount, Decimal.parse('999999999999.99'));
    });

    test('maps categoryId when present, null when absent', () {
      final withCategory = mapper.toEntity(row(categoryId: 'cat-food'));
      final withoutCategory = mapper.toEntity(row());

      expect(withCategory.categoryId, const CategoryId('cat-food'));
      expect(withoutCategory.categoryId, isNull);
    });

    test('maps payee when present, null when absent', () {
      final withPayee = mapper.toEntity(row(payee: 'Amazon'));
      final withoutPayee = mapper.toEntity(row());

      expect(withPayee.payee?.value, 'Amazon');
      expect(withoutPayee.payee, isNull);
    });

    test('throws FinanceException when payee column is an empty string', () {
      expect(
        () => mapper.toEntity(row(payee: '')),
        throwsA(isA<FinanceException>()),
      );
    });

    test('maps transferPairId to transferCounterpartId', () {
      final txn = mapper.toEntity(row(
        type: 'transfer',
        transferPairId: 'txn-counterpart',
      ));
      expect(txn.transferCounterpartId, const TransactionId('txn-counterpart'));
    });

    test('maps note when present, null when absent', () {
      final withNote = mapper.toEntity(row(note: 'Monthly rent'));
      final withoutNote = mapper.toEntity(row());

      expect(withNote.note, 'Monthly rent');
      expect(withoutNote.note, isNull);
    });

    test('maps a non-empty attachmentIds list', () {
      final txn = mapper.toEntity(row(attachmentIds: const ['att-1', 'att-2']));
      expect(txn.attachmentIds, ['att-1', 'att-2']);
    });

    test('maps an empty attachmentIds list as empty, not null', () {
      final txn = mapper.toEntity(row());
      expect(txn.attachmentIds, isEmpty);
    });

    test('maps every TransactionType column value back to its enum', () {
      for (final type in TransactionType.values) {
        final source = type == TransactionType.transfer
            ? row(type: type.name, transferPairId: 'pair')
            : row(type: type.name);
        expect(mapper.toEntity(source).type, type);
      }
    });

    test('throws FinanceException for an unrecognized transaction_type value',
        () {
      expect(
        () => mapper.toEntity(row(type: 'not_a_real_type')),
        throwsA(isA<FinanceException>()),
      );
    });

    test('ignores deletedAt on the row (Transaction has no such field)', () {
      final txn = mapper.toEntity(row(deletedAt: DateTime(2024, 6, 20)));
      expect(txn.id, const TransactionId('txn-1'));
    });

    test('preserves Unicode payee and note text', () {
      final txn = mapper.toEntity(row(
        payee: 'Café Périphérique 咖啡店',
        note: 'Résumé — 备注 🎉',
      ));
      expect(txn.payee?.value, 'Café Périphérique 咖啡店');
      expect(txn.note, 'Résumé — 备注 🎉');
    });
  });

  group('TransactionMapper round-trip', () {
    test('Transaction -> TransactionRow -> Transaction preserves all fields',
        () {
      final original = transaction(
        id: 'txn-rt',
        workspaceId: 'ws-rt',
        accountId: 'acc-rt',
        amount: '4999.42',
        currency: 'USD',
        categoryId: const CategoryId('cat-travel'),
        payee: Payee('Airline'),
        note: 'Business trip',
        attachmentIds: const ['att-1'],
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.accountId, original.accountId);
      expect(restored.type, original.type);
      expect(restored.amount.amount, original.amount.amount);
      expect(restored.amount.currency.value, original.amount.currency.value);
      expect(restored.categoryId, original.categoryId);
      expect(restored.payee, original.payee);
      expect(restored.note, original.note);
      expect(restored.date, original.date);
      expect(restored.attachmentIds, original.attachmentIds);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trips a transfer leg preserving transferCounterpartId', () {
      final original = transaction(
        id: 'txn-debit',
        type: TransactionType.transfer,
        transferCounterpartId: const TransactionId('txn-credit'),
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.transferCounterpartId, const TransactionId('txn-credit'));
      expect(restored.type, TransactionType.transfer);
    });

    test('round-trip is exact for a zero-decimal currency (JPY)', () {
      final original = transaction(currency: 'JPY', amount: '5000');
      final restored = mapper.toEntity(mapper.toRow(original));
      expect(restored.amount.amount, Decimal.parse('5000'));
    });

    test('round-trip is exact for a three-decimal currency (BHD)', () {
      final original = transaction(currency: 'BHD', amount: '12.345');
      final restored = mapper.toEntity(mapper.toRow(original));
      expect(restored.amount.amount, Decimal.parse('12.345'));
    });

    test('round-trip preserves an empty attachmentIds list', () {
      final original = transaction();
      final restored = mapper.toEntity(mapper.toRow(original));
      expect(restored.attachmentIds, isEmpty);
    });
  });
}
