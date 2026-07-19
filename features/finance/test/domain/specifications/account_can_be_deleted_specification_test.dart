import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_deleted_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_account_repository.dart';
import '../../helpers/fake_transaction_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');
const _ws = 'ws-1';

Account _account(String id, {bool isActive = true}) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: 'Test Account',
    type: AccountType.savings,
    currency: _inr,
    initialBalance: Money(amount: Decimal.zero, currency: _inr),
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _transaction(String id, String accountId) {
  final date = DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: AccountId(accountId),
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse('100'), currency: _inr),
    date: TransactionDate(date),
    createdAt: date,
    updatedAt: date,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late AccountCanBeDeletedSpecification spec;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    spec = AccountCanBeDeletedSpecification(
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
    );
  });

  group('AccountCanBeDeletedSpecification', () {
    // ── Happy path ────────────────────────────────────────────────────────────

    test('is satisfied when account exists and has no transactions', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );

      expect(result.isValid, isTrue);
      expect(result.failures, isEmpty);
    });

    // ── Account not found ─────────────────────────────────────────────────────

    test('fails when account does not exist', () async {
      final result = await spec.check(
        const AccountId('no-such'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures, hasLength(1));
      expect(result.failures.first.field, 'accountId');
      expect(result.failures.first.message, contains('does not exist'));
    });

    // ── Active transactions ───────────────────────────────────────────────────

    test('fails when account has one active transaction', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_transaction('txn-1', 'acc-1')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.first.message,
        contains('active transactions'),
      );
    });

    test('fails when account has multiple active transactions', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _transaction('txn-1', 'acc-1'),
        _transaction('txn-2', 'acc-1'),
        _transaction('txn-3', 'acc-1'),
      ]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
    });

    test('is satisfied when another account owns the transactions', () async {
      accountRepo.seed([_account('acc-1'), _account('acc-2')]);
      txnRepo.seed([_transaction('txn-1', 'acc-2')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );

      expect(result.isValid, isTrue);
    });

    // ── Boundary: empty transaction list ──────────────────────────────────────

    test('is satisfied when transaction store is empty for existing account',
        () async {
      accountRepo.seed([_account('acc-1')]);
      // txnRepo has nothing seeded

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );

      expect(result.isValid, isTrue);
    });

    // ── Immutability ──────────────────────────────────────────────────────────

    test('spec instance is reusable across multiple checks', () async {
      accountRepo.seed([_account('acc-1'), _account('acc-2')]);
      txnRepo.seed([_transaction('txn-1', 'acc-2')]);

      final r1 = await spec.check(const AccountId('acc-1'), workspaceId: _ws);
      final r2 = await spec.check(const AccountId('acc-2'), workspaceId: _ws);
      final r3 = await spec.check(const AccountId('no-such'), workspaceId: _ws);

      expect(r1.isValid, isTrue);
      expect(r2.isInvalid, isTrue);
      expect(r3.isInvalid, isTrue);
    });
  });
}
