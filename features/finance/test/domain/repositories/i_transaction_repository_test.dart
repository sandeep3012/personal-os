import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_page.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

// ── Fake implementation ───────────────────────────────────────────────────────

final class _FakeTransactionRepository implements ITransactionRepository {
  final List<Transaction> _store = [];

  @override
  FutureResult<Transaction?> findById(
    TransactionId id, {
    required String workspaceId,
  }) async =>
      Result.success(_store.where((t) => t.id == id).firstOrNull);

  @override
  FutureResult<List<Transaction>> findByAccount(
    AccountId accountId, {
    required String workspaceId,
    DateRange? dateRange,
  }) async =>
      Result.success(
        _store.where((t) {
          if (t.accountId != accountId) return false;
          if (dateRange != null && !dateRange.contains(t.date.value)) {
            return false;
          }
          return true;
        }).toList(),
      );

  @override
  FutureResult<List<Transaction>> findByPeriod(
    FinancePeriod period, {
    required String workspaceId,
  }) async {
    final range = DateRange(
      start: DateTime(period.year, period.month),
      end: DateTime(period.year, period.month + 1, 0),
    );
    return Result.success(
      _store.where((t) => range.contains(t.date.value)).toList(),
    );
  }

  @override
  FutureResult<List<Transaction>> findByCategory(
    CategoryId categoryId, {
    required String workspaceId,
    FinancePeriod? period,
  }) async {
    DateRange? range;
    if (period != null) {
      range = DateRange(
        start: DateTime(period.year, period.month),
        end: DateTime(period.year, period.month + 1, 0),
      );
    }
    return Result.success(
      _store.where((t) {
        if (t.categoryId != categoryId) return false;
        if (range != null && !range.contains(t.date.value)) return false;
        return true;
      }).toList(),
    );
  }

  @override
  FutureResult<TransactionPage> query(TransactionQuery query) async {
    final filtered = _store.where((t) {
      if (t.workspaceId != query.workspaceId) return false;
      if (query.accountId != null && t.accountId != query.accountId) {
        return false;
      }
      if (query.categoryId != null && t.categoryId != query.categoryId) {
        return false;
      }
      if (query.type != null && t.type != query.type) return false;
      if (query.dateRange != null &&
          !query.dateRange!.contains(t.date.value)) {
        return false;
      }
      if (query.payeeNameContains != null &&
          query.payeeNameContains!.isNotEmpty) {
        final name = t.payee?.value;
        if (name == null) return false;
        if (!name
            .toLowerCase()
            .contains(query.payeeNameContains!.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    final total = filtered.length;
    final start = query.pageIndex * query.pageSize;
    final end = (start + query.pageSize).clamp(0, total);
    final items =
        start >= total ? <Transaction>[] : filtered.sublist(start, end);

    return Result.success(TransactionPage(
      items: List.unmodifiable(items),
      totalCount: total,
      hasNextPage: end < total,
    ));
  }

  @override
  FutureResult<List<Transaction>> findActiveByAccount(
    AccountId accountId, {
    required String workspaceId,
  }) async =>
      Result.success(
        _store.where((t) => t.accountId == accountId).toList(),
      );

  @override
  FutureResult<void> save(Transaction transaction) async {
    _store.removeWhere((t) => t.id == transaction.id);
    _store.add(transaction);
    return const Result.success(null);
  }

  @override
  FutureResult<void> saveTransferPair(
    Transaction debit,
    Transaction credit,
  ) async {
    _store
      ..removeWhere((t) => t.id == debit.id || t.id == credit.id)
      ..add(debit)
      ..add(credit);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(
    TransactionId id, {
    required String workspaceId,
  }) async {
    _store.removeWhere((t) => t.id == id);
    return const Result.success(null);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');
const _ws = 'ws-1';

Transaction _expense(
  String id, {
  String accountId = 'acc-1',
  String amount = '100',
  CategoryId? categoryId,
  DateTime? date,
}) {
  final d = date ?? DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: AccountId(accountId),
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse(amount), currency: _inr),
    categoryId: categoryId,
    date: TransactionDate(d),
    createdAt: d,
    updatedAt: d,
  );
}

(Transaction, Transaction) _transferPair(String debitId, String creditId) {
  final debit = Transaction(
    id: TransactionId(debitId),
    workspaceId: _ws,
    accountId: const AccountId('acc-1'),
    type: TransactionType.transfer,
    amount: Money(amount: Decimal.parse('500'), currency: _inr),
    date: TransactionDate(DateTime(2024, 6, 15)),
    transferCounterpartId: TransactionId(creditId),
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2024, 6, 15),
  );
  final credit = Transaction(
    id: TransactionId(creditId),
    workspaceId: _ws,
    accountId: const AccountId('acc-2'),
    type: TransactionType.transfer,
    amount: Money(amount: Decimal.parse('500'), currency: _inr),
    date: TransactionDate(DateTime(2024, 6, 15)),
    transferCounterpartId: TransactionId(debitId),
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2024, 6, 15),
  );
  return (debit, credit);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late ITransactionRepository repository;

  setUp(() => repository = _FakeTransactionRepository());

  group('ITransactionRepository contract', () {
    // ── findByAccount ─────────────────────────────────────────────────────────

    test('findByAccount returns empty list when no transactions exist', () async {
      final result = await repository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('save persists a transaction and findByAccount returns it', () async {
      await repository.save(_expense('txn-1'));

      final result = await repository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );
      expect(result.valueOrNull, hasLength(1));
    });

    test('findByAccount with dateRange filters correctly', () async {
      await repository.save(_expense('in', date: DateTime(2024, 6, 15)));
      await repository.save(_expense('out', date: DateTime(2024, 7, 1)));

      final result = await repository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: _ws,
        dateRange: DateRange(
          start: DateTime(2024, 6, 1),
          end: DateTime(2024, 6, 30),
        ),
      );
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('in'));
    });

    test('findByAccount does not return transactions for a different account',
        () async {
      await repository.save(_expense('txn-a', accountId: 'acc-2'));

      final result = await repository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );
      expect(result.valueOrNull, isEmpty);
    });

    // ── findById ──────────────────────────────────────────────────────────────

    test('findById returns matching transaction', () async {
      await repository.save(_expense('txn-2'));

      final result = await repository.findById(
        const TransactionId('txn-2'),
        workspaceId: _ws,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, const TransactionId('txn-2'));
    });

    test('findById returns null for unknown id', () async {
      final result = await repository.findById(
        const TransactionId('no-such'),
        workspaceId: _ws,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    // ── findByPeriod ──────────────────────────────────────────────────────────

    test('findByPeriod returns transactions within the calendar month', () async {
      await repository.save(_expense('june', date: DateTime(2024, 6, 15)));
      await repository.save(_expense('july', date: DateTime(2024, 7, 1)));

      final result = await repository.findByPeriod(
        FinancePeriod(year: 2024, month: 6),
        workspaceId: _ws,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('june'));
    });

    test('findByPeriod returns empty list when no transactions in period', () async {
      await repository.save(_expense('may', date: DateTime(2024, 5, 31)));

      final result = await repository.findByPeriod(
        FinancePeriod(year: 2024, month: 6),
        workspaceId: _ws,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('findByPeriod handles December boundary correctly', () async {
      await repository.save(_expense('dec31', date: DateTime(2024, 12, 31)));
      await repository.save(_expense('jan1', date: DateTime(2025, 1, 1)));

      final result = await repository.findByPeriod(
        FinancePeriod(year: 2024, month: 12),
        workspaceId: _ws,
      );
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('dec31'));
    });

    // ── findByCategory ────────────────────────────────────────────────────────

    test('findByCategory returns only matching transactions', () async {
      await repository.save(
        _expense('cat', categoryId: const CategoryId('cat-food')),
      );
      await repository.save(_expense('no-cat'));

      final result = await repository.findByCategory(
        const CategoryId('cat-food'),
        workspaceId: _ws,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('cat'));
    });

    test('findByCategory with period filters by month', () async {
      await repository.save(_expense(
        'june-food',
        categoryId: const CategoryId('cat-food'),
        date: DateTime(2024, 6, 15),
      ));
      await repository.save(_expense(
        'july-food',
        categoryId: const CategoryId('cat-food'),
        date: DateTime(2024, 7, 5),
      ));

      final result = await repository.findByCategory(
        const CategoryId('cat-food'),
        workspaceId: _ws,
        period: FinancePeriod(year: 2024, month: 6),
      );
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('june-food'));
    });

    test('findByCategory without period returns all matching transactions', () async {
      await repository.save(_expense(
        'june-food',
        categoryId: const CategoryId('cat-food'),
        date: DateTime(2024, 6, 15),
      ));
      await repository.save(_expense(
        'july-food',
        categoryId: const CategoryId('cat-food'),
        date: DateTime(2024, 7, 5),
      ));

      final result = await repository.findByCategory(
        const CategoryId('cat-food'),
        workspaceId: _ws,
      );
      expect(result.valueOrNull, hasLength(2));
    });

    // ── query ─────────────────────────────────────────────────────────────────

    test('query returns all workspace transactions when no filters set', () async {
      await repository.save(_expense('t1'));
      await repository.save(_expense('t2'));

      final result = await repository.query(
        const TransactionQuery(workspaceId: _ws),
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.totalCount, 2);
      expect(result.valueOrNull!.items, hasLength(2));
    });

    test('query filters by accountId', () async {
      await repository.save(_expense('acc1-txn', accountId: 'acc-1'));
      await repository.save(_expense('acc2-txn', accountId: 'acc-2'));

      final result = await repository.query(
        const TransactionQuery(
          workspaceId: _ws,
          accountId: AccountId('acc-1'),
        ),
      );
      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items.first.id, const TransactionId('acc1-txn'));
    });

    test('query filters by type', () async {
      await repository.save(_expense('exp'));
      await repository.save(Transaction(
        id: const TransactionId('inc'),
        workspaceId: _ws,
        accountId: const AccountId('acc-1'),
        type: TransactionType.income,
        amount: Money(amount: Decimal.parse('200'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
        createdAt: DateTime(2024, 6, 15),
        updatedAt: DateTime(2024, 6, 15),
      ));

      final result = await repository.query(
        const TransactionQuery(
          workspaceId: _ws,
          type: TransactionType.expense,
        ),
      );
      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items.first.id, const TransactionId('exp'));
    });

    test('query paginates results correctly', () async {
      for (var i = 1; i <= 5; i++) {
        await repository.save(_expense('t$i'));
      }

      final page0 = await repository.query(
        const TransactionQuery(workspaceId: _ws, pageIndex: 0, pageSize: 2),
      );
      final page1 = await repository.query(
        const TransactionQuery(workspaceId: _ws, pageIndex: 1, pageSize: 2),
      );

      expect(page0.valueOrNull!.totalCount, 5);
      expect(page0.valueOrNull!.items, hasLength(2));
      expect(page0.valueOrNull!.hasNextPage, isTrue);

      expect(page1.valueOrNull!.items, hasLength(2));
      expect(page1.valueOrNull!.hasNextPage, isTrue);
    });

    test('query hasNextPage is false on last page', () async {
      await repository.save(_expense('t1'));
      await repository.save(_expense('t2'));
      await repository.save(_expense('t3'));

      final result = await repository.query(
        const TransactionQuery(workspaceId: _ws, pageIndex: 1, pageSize: 2),
      );
      expect(result.valueOrNull!.items, hasLength(1));
      expect(result.valueOrNull!.hasNextPage, isFalse);
    });

    test('query returns empty page when no transactions match', () async {
      final result = await repository.query(
        const TransactionQuery(workspaceId: _ws),
      );
      expect(result.valueOrNull!.totalCount, 0);
      expect(result.valueOrNull!.items, isEmpty);
      expect(result.valueOrNull!.hasNextPage, isFalse);
    });

    // ── findActiveByAccount ───────────────────────────────────────────────────

    test('findActiveByAccount returns all transactions for the account', () async {
      await repository.save(_expense('t5', accountId: 'acc-1'));
      await repository.save(_expense('t6', accountId: 'acc-2'));

      final result = await repository.findActiveByAccount(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );
      expect(result.valueOrNull, hasLength(1));
    });

    // ── saveTransferPair ──────────────────────────────────────────────────────

    test('saveTransferPair stores both legs atomically', () async {
      final (debit, credit) = _transferPair('txn-d', 'txn-c');
      await repository.saveTransferPair(debit, credit);

      final debitResult = await repository.findById(
        const TransactionId('txn-d'),
        workspaceId: _ws,
      );
      final creditResult = await repository.findById(
        const TransactionId('txn-c'),
        workspaceId: _ws,
      );
      expect(debitResult.valueOrNull, isNotNull);
      expect(creditResult.valueOrNull, isNotNull);
    });

    // ── softDelete ────────────────────────────────────────────────────────────

    test('softDelete removes the transaction from results', () async {
      await repository.save(_expense('txn-7'));
      await repository.softDelete(
        const TransactionId('txn-7'),
        workspaceId: _ws,
      );

      final result = await repository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );
      expect(result.valueOrNull, isEmpty);
    });

    test('softDelete is idempotent when transaction does not exist', () async {
      final result = await repository.softDelete(
        const TransactionId('never-existed'),
        workspaceId: _ws,
      );
      expect(result.isSuccess, isTrue);
    });

    test('softDelete does not affect other transactions', () async {
      await repository.save(_expense('keep'));
      await repository.save(_expense('remove', accountId: 'acc-2'));

      await repository.softDelete(
        const TransactionId('remove'),
        workspaceId: _ws,
      );

      final result = await repository.findByAccount(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const TransactionId('keep'));
    });
  });
}
