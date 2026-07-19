import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import 'support/finance_integration_container.dart';

// Exercises ITransactionRepository end-to-end through the real composed
// stack. Repository is resolved from FinanceModule, never constructed
// manually.

Transaction _transaction({
  String id = 'txn-1',
  String workspaceId = 'ws-1',
  String accountId = 'acc-1',
  TransactionType type = TransactionType.expense,
  String amount = '100',
  String currency = 'INR',
  CategoryId? categoryId,
  Payee? payee,
  String? note,
  List<String> attachmentIds = const [],
  DateTime? date,
  TransactionId? transferCounterpartId,
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
    createdAt: d,
    updatedAt: d,
  );
}

void main() {
  late FinanceIntegrationContainer container;

  setUp(() => container = FinanceIntegrationContainer());

  group('TransactionRepository — CRUD', () {
    test('save() persists a new transaction, retrievable via findById',
        () async {
      final saveResult =
          await container.transactionRepository.save(_transaction(id: 'txn-1'));
      expect(saveResult.isSuccess, isTrue);

      final result = await container.transactionRepository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull, isNotNull);
      expect(result.valueOrNull!.amount.amount, Decimal.parse('100'));
    });

    test('save() with an existing id updates in place', () async {
      await container.transactionRepository
          .save(_transaction(id: 'txn-1', amount: '100'));
      await container.transactionRepository
          .save(_transaction(id: 'txn-1', amount: '250'));

      final result = await container.transactionRepository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.amount.amount, Decimal.parse('250'));
    });

    test('findById returns null for a non-existent transaction', () async {
      final result = await container.transactionRepository.findById(
        const TransactionId('missing'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull, isNull);
    });

    test('findByAccount returns only transactions for that account', () async {
      await container.transactionRepository
          .save(_transaction(id: 't1', accountId: 'acc-1'));
      await container.transactionRepository
          .save(_transaction(id: 't2', accountId: 'acc-2'));

      final result = await container.transactionRepository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('t1'));
    });

    test('findByAccount with a DateRange filters correctly', () async {
      await container.transactionRepository.save(
        _transaction(id: 'in-range', date: DateTime(2024, 6, 15)),
      );
      await container.transactionRepository.save(
        _transaction(id: 'out-of-range', date: DateTime(2024, 7, 1)),
      );

      final result = await container.transactionRepository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
        dateRange: DateRange(
          start: DateTime(2024, 6, 1),
          end: DateTime(2024, 6, 30),
        ),
      );
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('in-range'));
    });

    test('findByCategory returns only matching transactions', () async {
      await container.transactionRepository.save(_transaction(
        id: 't1',
        categoryId: const CategoryId('cat-food'),
      ));
      await container.transactionRepository.save(_transaction(id: 't2'));

      final result = await container.transactionRepository.findByCategory(
        const CategoryId('cat-food'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('t1'));
    });

    test('findByPeriod returns transactions within the calendar month',
        () async {
      await container.transactionRepository
          .save(_transaction(id: 'june', date: DateTime(2024, 6, 15)));
      await container.transactionRepository
          .save(_transaction(id: 'july', date: DateTime(2024, 7, 1)));

      final result = await container.transactionRepository.findByPeriod(
        FinancePeriod(year: 2024, month: 6),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('june'));
    });

    test('query() returns a paginated TransactionPage', () async {
      for (var i = 1; i <= 5; i++) {
        await container.transactionRepository
            .save(_transaction(id: 't$i', date: DateTime(2024, 6, i)));
      }

      final result = await container.transactionRepository.query(
        const TransactionQuery(workspaceId: 'ws-1', pageIndex: 0, pageSize: 2),
      );
      expect(result.valueOrNull!.totalCount, 5);
      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });

    test('findActiveByAccount returns all transactions with no date filter',
        () async {
      await container.transactionRepository.save(
        _transaction(id: 'old', date: DateTime(2020, 1, 1)),
      );
      await container.transactionRepository.save(
        _transaction(id: 'new', date: DateTime(2024, 6, 15)),
      );

      final result = await container.transactionRepository.findActiveByAccount(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull, hasLength(2));
    });

    test('softDelete excludes the transaction from findByAccount', () async {
      await container.transactionRepository.save(_transaction(id: 'txn-1'));

      await container.transactionRepository.softDelete(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );

      final result = await container.transactionRepository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull, isEmpty);

      final byId = await container.transactionRepository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(byId.valueOrNull, isNull);
    });
  });

  group('TransactionRepository — Money round-trip', () {
    test('a large amount round-trips without precision loss', () async {
      await container.transactionRepository
          .save(_transaction(id: 'txn-1', amount: '999999999999.99'));

      final result = await container.transactionRepository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.amount.amount, Decimal.parse('999999999999.99'));
    });

    test('a zero-decimal currency (JPY) round-trips exactly', () async {
      await container.transactionRepository.save(
        _transaction(id: 'txn-1', amount: '5000', currency: 'JPY'),
      );
      final result = await container.transactionRepository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.amount.amount, Decimal.parse('5000'));
    });
  });

  group('TransactionRepository — TransactionType enum round-trip', () {
    for (final type in TransactionType.values) {
      test('${type.name} round-trips through save/findById', () async {
        final txn = type == TransactionType.transfer
            ? _transaction(
                id: 'txn-${type.name}',
                type: type,
                transferCounterpartId: const TransactionId('txn-counterpart'),
              )
            : _transaction(id: 'txn-${type.name}', type: type);
        await container.transactionRepository.save(txn);

        final result = await container.transactionRepository.findById(
          TransactionId('txn-${type.name}'),
          workspaceId: 'ws-1',
        );
        expect(result.valueOrNull!.type, type);
      });
    }
  });

  group('TransactionRepository — Date boundaries', () {
    test('findByPeriod handles the December → January year boundary', () async {
      await container.transactionRepository.save(
        _transaction(id: 'dec-31', date: DateTime(2024, 12, 31)),
      );
      await container.transactionRepository.save(
        _transaction(id: 'jan-1', date: DateTime(2025, 1, 1)),
      );

      final decResult = await container.transactionRepository.findByPeriod(
        FinancePeriod(year: 2024, month: 12),
        workspaceId: 'ws-1',
      );
      final janResult = await container.transactionRepository.findByPeriod(
        FinancePeriod(year: 2025, month: 1),
        workspaceId: 'ws-1',
      );

      expect(decResult.valueOrNull!.map((t) => t.id.value), ['dec-31']);
      expect(janResult.valueOrNull!.map((t) => t.id.value), ['jan-1']);
    });

    test('findByAccount date range is inclusive on both boundaries', () async {
      await container.transactionRepository.save(
        _transaction(id: 'first-day', date: DateTime(2024, 6, 1)),
      );
      await container.transactionRepository.save(
        _transaction(id: 'last-day', date: DateTime(2024, 6, 30)),
      );

      final result = await container.transactionRepository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
        dateRange: DateRange(
          start: DateTime(2024, 6, 1),
          end: DateTime(2024, 6, 30),
        ),
      );
      expect(result.valueOrNull, hasLength(2));
    });

    test('TransactionDate strips time-of-day and round-trips correctly',
        () async {
      await container.transactionRepository.save(
        _transaction(id: 'txn-1', date: DateTime(2024, 6, 15, 23, 59, 59)),
      );

      final result = await container.transactionRepository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.date.value, DateTime(2024, 6, 15));
    });
  });

  group('TransactionRepository — Unicode', () {
    test('payee, note, and attachmentIds with Unicode content round-trip',
        () async {
      await container.transactionRepository.save(_transaction(
        id: 'txn-1',
        payee: Payee('Café Périphérique 咖啡店'),
        note: 'Résumé — 备注 🎉',
        attachmentIds: const ['att-résumé-1', 'att-儲蓄-2'],
      ));

      final result = await container.transactionRepository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.payee?.value, 'Café Périphérique 咖啡店');
      expect(result.valueOrNull!.note, 'Résumé — 备注 🎉');
      expect(
        result.valueOrNull!.attachmentIds,
        ['att-résumé-1', 'att-儲蓄-2'],
      );
    });

    test('an empty attachmentIds list round-trips as empty', () async {
      await container.transactionRepository.save(_transaction(id: 'txn-1'));

      final result = await container.transactionRepository.findById(
        const TransactionId('txn-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.attachmentIds, isEmpty);
    });
  });
}
