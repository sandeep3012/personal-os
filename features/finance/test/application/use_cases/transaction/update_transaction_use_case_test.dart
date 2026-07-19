import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/transaction/update_transaction_use_case.dart';
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

import '../../../helpers/fake_transaction_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');
Money _money(String amount) =>
    Money(amount: Decimal.parse(amount), currency: _inr);
const _accId = AccountId('acc-1');

Transaction _expense(String id, {String amount = '100'}) {
  final now = DateTime(2024, 6, 1);
  return Transaction(
    id: TransactionId(id),
    workspaceId: 'ws-1',
    accountId: _accId,
    type: TransactionType.expense,
    amount: _money(amount),
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeTransactionRepository repo;
  late UpdateTransactionUseCase useCase;

  setUp(() {
    repo = FakeTransactionRepository();
    useCase = UpdateTransactionUseCase(transactionRepository: repo);
  });

  group('UpdateTransactionUseCase', () {
    test('updates amount when provided', () async {
      repo.seed([_expense('txn-1')]);

      final result = await useCase.execute(UpdateTransactionInput(
        transactionId: const TransactionId('txn-1'),
        workspaceId: 'ws-1',
        amount: _money('999'),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.amount.amount, Decimal.parse('999'));
    });

    test('keeps existing amount when amount is null', () async {
      repo.seed([_expense('txn-1', amount: '250')]);

      final result = await useCase.execute(const UpdateTransactionInput(
        transactionId: TransactionId('txn-1'),
        workspaceId: 'ws-1',
      ));

      expect(result.valueOrNull!.amount.amount, Decimal.parse('250'));
    });

    test('updates payee when provided', () async {
      repo.seed([_expense('txn-1')]);

      final result = await useCase.execute(UpdateTransactionInput(
        transactionId: const TransactionId('txn-1'),
        workspaceId: 'ws-1',
        payee: Payee('Netflix'),
      ));

      expect(result.valueOrNull!.payee?.value, 'Netflix');
    });

    test('updates categoryId when provided', () async {
      repo.seed([_expense('txn-1')]);

      final result = await useCase.execute(const UpdateTransactionInput(
        transactionId: TransactionId('txn-1'),
        workspaceId: 'ws-1',
        categoryId: CategoryId('cat-entertainment'),
      ));

      expect(result.valueOrNull!.categoryId?.value, 'cat-entertainment');
    });

    test('updates note when provided', () async {
      repo.seed([_expense('txn-1')]);

      final result = await useCase.execute(const UpdateTransactionInput(
        transactionId: TransactionId('txn-1'),
        workspaceId: 'ws-1',
        note: 'Updated note',
      ));

      expect(result.valueOrNull!.note, 'Updated note');
    });

    test('preserves type and accountId (immutable after creation)', () async {
      repo.seed([_expense('txn-1')]);

      final result = await useCase.execute(UpdateTransactionInput(
        transactionId: const TransactionId('txn-1'),
        workspaceId: 'ws-1',
        amount: _money('200'),
      ));

      expect(result.valueOrNull!.type, TransactionType.expense);
      expect(result.valueOrNull!.accountId, _accId);
    });

    test('persists the updated transaction', () async {
      repo.seed([_expense('txn-1')]);

      await useCase.execute(UpdateTransactionInput(
        transactionId: const TransactionId('txn-1'),
        workspaceId: 'ws-1',
        amount: _money('777'),
      ));

      expect(repo.store.first.amount.amount, Decimal.parse('777'));
    });

    test('fails with FinanceException when transaction not found', () async {
      final result = await useCase.execute(const UpdateTransactionInput(
        transactionId: TransactionId('missing'),
        workspaceId: 'ws-1',
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });
  });
}
