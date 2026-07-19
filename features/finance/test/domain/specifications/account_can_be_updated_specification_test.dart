import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_updated_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_account_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');
const _ws = 'ws-1';

Account _account(String id, {String name = 'My Account', bool isActive = true}) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: name,
    type: AccountType.savings,
    currency: _inr,
    initialBalance: Money(amount: Decimal.zero, currency: _inr),
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository accountRepo;
  late AccountCanBeUpdatedSpecification spec;

  setUp(() {
    accountRepo = FakeAccountRepository();
    spec = AccountCanBeUpdatedSpecification(accountRepository: accountRepo);
  });

  group('AccountCanBeUpdatedSpecification', () {
    // ── Happy path ────────────────────────────────────────────────────────────

    test('is satisfied when account exists and no name change is requested',
        () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );

      expect(result.isValid, isTrue);
    });

    test('is satisfied when account exists and new name is valid', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        name: 'New Valid Name',
      );

      expect(result.isValid, isTrue);
    });

    test('is satisfied for an inactive account with no name change', () async {
      accountRepo.seed([_account('acc-1', isActive: false)]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
      );

      expect(result.isValid, isTrue);
    });

    // ── Account not found ─────────────────────────────────────────────────────

    test('fails when account does not exist', () async {
      final result = await spec.check(
        const AccountId('no-such'),
        workspaceId: _ws,
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures.first.field, 'accountId');
      expect(result.failures.first.message, contains('does not exist'));
    });

    // ── Name validation ───────────────────────────────────────────────────────

    test('fails when new name is empty', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        name: '',
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any((f) => f.field == 'name'),
        isTrue,
      );
      expect(
        result.failures.first.message,
        contains('must not be empty'),
      );
    });

    test('fails when new name is only whitespace', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        name: '   ',
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures.any((f) => f.field == 'name'), isTrue);
    });

    test('fails when new name exceeds 100 characters', () async {
      accountRepo.seed([_account('acc-1')]);
      final longName = 'A' * 101;

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        name: longName,
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any(
          (f) => f.field == 'name' && f.message.contains('100 characters'),
        ),
        isTrue,
      );
    });

    test('is satisfied when name is exactly 100 characters', () async {
      accountRepo.seed([_account('acc-1')]);
      final name100 = 'A' * 100;

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        name: name100,
      );

      expect(result.isValid, isTrue);
    });

    test('is satisfied when name is a single character', () async {
      accountRepo.seed([_account('acc-1')]);

      final result = await spec.check(
        const AccountId('acc-1'),
        workspaceId: _ws,
        name: 'A',
      );

      expect(result.isValid, isTrue);
    });

    // ── Both name invalid and account missing accumulate failures ─────────────

    test('accumulates name failure and account-not-found failure', () async {
      final result = await spec.check(
        const AccountId('no-such'),
        workspaceId: _ws,
        name: '',
      );

      expect(result.isInvalid, isTrue);
      expect(result.failures.length, greaterThanOrEqualTo(2));
      expect(result.failures.any((f) => f.field == 'name'), isTrue);
      expect(result.failures.any((f) => f.field == 'accountId'), isTrue);
    });
  });
}
