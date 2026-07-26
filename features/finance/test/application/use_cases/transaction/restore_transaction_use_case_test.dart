import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/transaction/restore_transaction_use_case.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_transaction_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');

Transaction _expense(String id) {
  final now = DateTime(2024, 6, 1);
  return Transaction(
    id: TransactionId(id),
    workspaceId: 'ws-1',
    accountId: const AccountId('acc-1'),
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse('100'), currency: _inr),
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeTransactionRepository repo;
  late RestoreTransactionUseCase useCase;

  setUp(() {
    repo = FakeTransactionRepository();
    useCase = RestoreTransactionUseCase(transactionRepository: repo);
  });

  group('RestoreTransactionUseCase', () {
    test('reinstates a previously soft-deleted transaction', () async {
      repo.seed([_expense('txn-1')]);
      await repo.softDelete(const TransactionId('txn-1'), workspaceId: 'ws-1');
      expect(repo.store, isEmpty);

      final result = await useCase.execute(const RestoreTransactionInput(
        transactionId: TransactionId('txn-1'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(repo.store, hasLength(1));
      expect(repo.store.first.id.value, 'txn-1');
    });

    test('is idempotent when the transaction does not exist', () async {
      final result = await useCase.execute(const RestoreTransactionInput(
        transactionId: TransactionId('gone'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
    });

    test('is a no-op when the transaction was never deleted', () async {
      repo.seed([_expense('txn-1')]);

      final result = await useCase.execute(const RestoreTransactionInput(
        transactionId: TransactionId('txn-1'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(repo.store, hasLength(1));
    });

    test('returns void success value', () async {
      repo.seed([_expense('txn-1')]);
      await repo.softDelete(const TransactionId('txn-1'), workspaceId: 'ws-1');

      final result = await useCase.execute(const RestoreTransactionInput(
        transactionId: TransactionId('txn-1'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
    });
  });
}
