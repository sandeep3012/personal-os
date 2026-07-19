import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/specifications/transaction_can_be_created_specification.dart';
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
    name: 'Test Account',
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
  late TransactionCanBeCreatedSpecification spec;

  setUp(() {
    accountRepo = FakeAccountRepository();
    spec =
        TransactionCanBeCreatedSpecification(accountRepository: accountRepo);
  });

  group('TransactionCanBeCreatedSpecification', () {
    // ── Happy path ────────────────────────────────────────────────────────────

    test('is satisfied when account exists, is active, and currency matches',
        () async {
      accountRepo.seed([_account('acc-1', currency: 'INR')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        currency: CurrencyCode('INR'),
      );

      expect(result.isValid, isTrue);
    });

    // ── Account not found ─────────────────────────────────────────────────────

    test('fails when account does not exist', () async {
      final result = await spec.check(
        const AccountId('no-such'),
        workspaceId: _ws,
        currency: CurrencyCode('INR'),
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures.first.field, 'accountId');
      expect(result.failures.first.message, contains('does not exist'));
    });

    // ── Inactive account ──────────────────────────────────────────────────────

    test('fails when account is inactive', () async {
      accountRepo.seed([_account('acc-1', isActive: false, currency: 'INR')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        currency: CurrencyCode('INR'),
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures.first.field, 'accountId');
      expect(result.failures.first.message, contains('inactive'));
    });

    // ── Currency mismatch ─────────────────────────────────────────────────────

    test('fails when transaction currency does not match account currency',
        () async {
      accountRepo.seed([_account('acc-1', currency: 'INR')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        currency: CurrencyCode('USD'),
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any((f) => f.field == 'currency'),
        isTrue,
      );
      expect(
        result.failures.first.message,
        allOf(contains('USD'), contains('INR')),
      );
    });

    test('is satisfied with USD account and USD transaction', () async {
      accountRepo.seed([_account('acc-1', currency: 'USD')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        currency: CurrencyCode('USD'),
      );

      expect(result.isValid, isTrue);
    });

    // ── Both inactive and currency mismatch accumulate ────────────────────────

    test('accumulates inactive and currency-mismatch failures', () async {
      accountRepo.seed([_account('acc-1', isActive: false, currency: 'INR')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        currency: CurrencyCode('USD'),
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures.length, 2);
      expect(result.failures.any((f) => f.field == 'accountId'), isTrue);
      expect(result.failures.any((f) => f.field == 'currency'), isTrue);
    });

    // ── Different currencies ──────────────────────────────────────────────────

    test('fails for EUR transaction on GBP account', () async {
      accountRepo.seed([_account('acc-1', currency: 'GBP')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        currency: CurrencyCode('EUR'),
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures.any((f) => f.field == 'currency'), isTrue);
    });
  });
}
