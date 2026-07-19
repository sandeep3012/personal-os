import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/delete_account_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_deleted_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/fake_transaction_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');

Account _account(String id) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: 'ws-1',
    name: 'Account $id',
    type: AccountType.savings,
    currency: _inr,
    initialBalance: Money(amount: Decimal.zero, currency: _inr),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _transaction(String id, AccountId accountId) {
  final now = DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: 'ws-1',
    accountId: accountId,
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse('100'), currency: _inr),
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late DeleteAccountUseCase useCase;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    useCase = DeleteAccountUseCase(
      accountRepository: accountRepo,
      specification: AccountCanBeDeletedSpecification(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
      ),
    );
  });

  group('DeleteAccountUseCase', () {
    test('deletes account that has no transactions', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);

      final result = await useCase.execute(const DeleteAccountInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(accountRepo.store, isEmpty);
    });

    test('fails when account has active transactions (Invariant 5)', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_transaction('txn-1', accId)]);

      final result = await useCase.execute(const DeleteAccountInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(accountRepo.store, hasLength(1));
    });

    test('succeeds after all transactions have been removed', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      // empty transaction repo — no active transactions

      final result = await useCase.execute(const DeleteAccountInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
    });

    // ── Specification integration ─────────────────────────────────────────────

    test('fails when account does not exist (specification rejects)', () async {
      const accId = AccountId('never-existed');

      final result = await useCase.execute(const DeleteAccountInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(
        (result.exceptionOrNull as FinanceException).message,
        contains('does not exist'),
      );
    });

    test('softDelete is never called on the repository when validation fails',
        () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_transaction('txn-1', accId)]);

      await useCase.execute(const DeleteAccountInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      // The account must still be present — softDelete was never reached.
      expect(accountRepo.store, hasLength(1));
      expect(accountRepo.store.first.id, accId);
    });

    test('validation succeeds and softDelete proceeds normally', () async {
      const accId = AccountId('acc-1');
      accountRepo.seed([_account('acc-1'), _account('acc-2')]);

      final result = await useCase.execute(const DeleteAccountInput(
        accountId: accId,
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(accountRepo.store, hasLength(1));
      expect(accountRepo.store.first.id, const AccountId('acc-2'));
    });
  });
}
