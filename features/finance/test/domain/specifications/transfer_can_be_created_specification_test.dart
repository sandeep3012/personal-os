import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/specifications/transfer_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_account_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _ws = 'ws-1';

Account _account(
  String id, {
  bool isActive = true,
  String currency = 'INR',
}) {
  final cc = CurrencyCode(currency);
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: 'Account $id',
    type: AccountType.savings,
    currency: cc,
    initialBalance: Money(amount: Decimal.zero, currency: cc),
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late TransferCanBeCreatedSpecification spec;

  setUp(() {
    accountRepo = FakeAccountRepository();
    spec = TransferCanBeCreatedSpecification(accountRepository: accountRepo);
  });

  group('TransferCanBeCreatedSpecification', () {
    // ── Happy path ────────────────────────────────────────────────────────────

    test('is satisfied when both accounts exist, are active, and share currency',
        () async {
      accountRepo.seed([
        _account('acc-from', currency: 'INR'),
        _account('acc-to', currency: 'INR'),
      ]);

      final result = await spec.check(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        workspaceId: _ws,
      );

      expect(result.isValid, isTrue);
    });

    // ── Same account ──────────────────────────────────────────────────────────

    test('fails immediately when source and destination accounts are the same',
        () async {
      // Should not need the repository — fails before any I/O.
      final result = await spec.check(
        fromAccountId: const AccountId('acc-1'),
        toAccountId: const AccountId('acc-1'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any((f) => f.field == 'toAccountId'),
        isTrue,
      );
      expect(result.failures.first.message, contains('different'));
    });

    // ── Source account issues ─────────────────────────────────────────────────

    test('fails when source account does not exist', () async {
      accountRepo.seed([_account('acc-to')]);

      final result = await spec.check(
        fromAccountId: const AccountId('no-such'),
        toAccountId: const AccountId('acc-to'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any(
          (f) => f.field == 'fromAccountId' && f.message.contains('does not exist'),
        ),
        isTrue,
      );
    });

    test('fails when source account is inactive', () async {
      accountRepo.seed([
        _account('acc-from', isActive: false),
        _account('acc-to'),
      ]);

      final result = await spec.check(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any(
          (f) => f.field == 'fromAccountId' && f.message.contains('inactive'),
        ),
        isTrue,
      );
    });

    // ── Destination account issues ────────────────────────────────────────────

    test('fails when destination account does not exist', () async {
      accountRepo.seed([_account('acc-from')]);

      final result = await spec.check(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('no-such'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any(
          (f) => f.field == 'toAccountId' && f.message.contains('does not exist'),
        ),
        isTrue,
      );
    });

    test('fails when destination account is inactive', () async {
      accountRepo.seed([
        _account('acc-from'),
        _account('acc-to', isActive: false),
      ]);

      final result = await spec.check(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any(
          (f) => f.field == 'toAccountId' && f.message.contains('inactive'),
        ),
        isTrue,
      );
    });

    // ── Currency mismatch ─────────────────────────────────────────────────────

    test('fails when accounts have different currencies', () async {
      accountRepo.seed([
        _account('acc-from', currency: 'INR'),
        _account('acc-to', currency: 'USD'),
      ]);

      final result = await spec.check(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any((f) => f.field == 'currency'),
        isTrue,
      );
      expect(
        result.failures.any(
          (f) => f.message.contains('INR') && f.message.contains('USD'),
        ),
        isTrue,
      );
    });

    test('is satisfied when both accounts share USD currency', () async {
      accountRepo.seed([
        _account('acc-from', currency: 'USD'),
        _account('acc-to', currency: 'USD'),
      ]);

      final result = await spec.check(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        workspaceId: _ws,
      );

      expect(result.isValid, isTrue);
    });

    // ── Multiple failure accumulation ─────────────────────────────────────────

    test('accumulates failures when both accounts are missing', () async {
      final result = await spec.check(
        fromAccountId: const AccountId('missing-from'),
        toAccountId: const AccountId('missing-to'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any((f) => f.field == 'fromAccountId'),
        isTrue,
      );
      expect(
        result.failures.any((f) => f.field == 'toAccountId'),
        isTrue,
      );
    });

    test('accumulates failures when both accounts are inactive', () async {
      accountRepo.seed([
        _account('acc-from', isActive: false, currency: 'INR'),
        _account('acc-to', isActive: false, currency: 'INR'),
      ]);

      final result = await spec.check(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures.length, 2);
    });

    // ── Boundary: credit card accounts ────────────────────────────────────────

    test('is satisfied for transfer between two active credit-card accounts',
        () async {
      final cc = CurrencyCode('INR');
      final now = DateTime(2024, 1, 1);
      accountRepo.seed([
        Account(
          id: const AccountId('cc-from'),
          workspaceId: _ws,
          name: 'CC From',
          type: AccountType.creditCard,
          currency: cc,
          initialBalance: Money(amount: Decimal.zero, currency: cc),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Account(
          id: const AccountId('cc-to'),
          workspaceId: _ws,
          name: 'CC To',
          type: AccountType.creditCard,
          currency: cc,
          initialBalance: Money(amount: Decimal.zero, currency: cc),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final result = await spec.check(
        fromAccountId: const AccountId('cc-from'),
        toAccountId: const AccountId('cc-to'),
        workspaceId: _ws,
      );

      expect(result.isValid, isTrue);
    });
  });
}
