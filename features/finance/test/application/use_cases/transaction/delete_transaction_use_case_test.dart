import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/transaction/delete_transaction_use_case.dart';
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
  late DeleteTransactionUseCase useCase;

  setUp(() {
    repo = FakeTransactionRepository();
    useCase = DeleteTransactionUseCase(transactionRepository: repo);
  });

  group('DeleteTransactionUseCase', () {
    test('removes the transaction from the repository', () async {
      repo.seed([_expense('txn-1'), _expense('txn-2')]);

      final result = await useCase.execute(const DeleteTransactionInput(
        transactionId: TransactionId('txn-1'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(repo.store, hasLength(1));
      expect(repo.store.first.id.value, 'txn-2');
    });

    test('is idempotent when transaction does not exist', () async {
      final result = await useCase.execute(const DeleteTransactionInput(
        transactionId: TransactionId('gone'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
    });

    test('returns void success value', () async {
      repo.seed([_expense('txn-1')]);

      final result = await useCase.execute(const DeleteTransactionInput(
        transactionId: TransactionId('txn-1'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
    });
  });
}
