import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_created_specification.dart';
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
  late AccountCanBeCreatedSpecification spec;

  setUp(() {
    accountRepo = FakeAccountRepository();
    spec = AccountCanBeCreatedSpecification(accountRepository: accountRepo);
  });

  group('AccountCanBeCreatedSpecification', () {
    // ── Happy path ────────────────────────────────────────────────────────────

    test('is satisfied for a valid, unused name in an empty workspace',
        () async {
      final result = await spec.check('HDFC Savings', workspaceId: _ws);
      expect(result.isValid, isTrue);
    });

    test('is satisfied when only inactive accounts share a similar name',
        () async {
      accountRepo.seed([_account('acc-1', name: 'Old Account', isActive: false)]);

      final result = await spec.check('Old Account', workspaceId: _ws);
      expect(result.isValid, isTrue);
    });

    // ── Name validation ───────────────────────────────────────────────────────

    test('fails when name is empty', () async {
      final result = await spec.check('', workspaceId: _ws);
      expect(result.isInvalid, isTrue);
      expect(result.failures.any((f) => f.field == 'name'), isTrue);
      expect(result.failures.first.message, contains('must not be empty'));
    });

    test('fails when name is only whitespace', () async {
      final result = await spec.check('   ', workspaceId: _ws);
      expect(result.isInvalid, isTrue);
    });

    test('fails when name exceeds 100 characters', () async {
      final result = await spec.check('A' * 101, workspaceId: _ws);
      expect(result.isInvalid, isTrue);
      expect(
        result.failures.any((f) => f.message.contains('100 characters')),
        isTrue,
      );
    });

    test('is satisfied when name is exactly 100 characters', () async {
      final result = await spec.check('A' * 100, workspaceId: _ws);
      expect(result.isValid, isTrue);
    });

    // ── Duplicate detection ───────────────────────────────────────────────────

    test('fails when an active account already has the exact same name',
        () async {
      accountRepo.seed([_account('acc-1', name: 'HDFC Savings')]);

      final result = await spec.check('HDFC Savings', workspaceId: _ws);

      expect(result.isInvalid, isTrue);
      expect(result.failures.any((f) => f.field == 'name'), isTrue);
      expect(result.failures.first.message, contains('already exists'));
    });

    test('duplicate detection is case-insensitive', () async {
      accountRepo.seed([_account('acc-1', name: 'HDFC Savings')]);

      final result = await spec.check('hdfc savings', workspaceId: _ws);

      expect(result.isInvalid, isTrue);
    });

    test('duplicate detection ignores surrounding whitespace', () async {
      accountRepo.seed([_account('acc-1', name: 'HDFC Savings')]);

      final result = await spec.check('  HDFC Savings  ', workspaceId: _ws);

      expect(result.isInvalid, isTrue);
    });

    test('allows a name that only partially overlaps an existing name',
        () async {
      accountRepo.seed([_account('acc-1', name: 'HDFC Savings')]);

      final result = await spec.check('HDFC Current', workspaceId: _ws);

      expect(result.isValid, isTrue);
    });

    // ── Both name-invalid and duplicate accumulate failures ──────────────────

    test('accumulates the length failure and the duplicate failure together',
        () async {
      final longName = 'A' * 101;
      accountRepo.seed([_account('acc-1', name: longName)]);

      final result = await spec.check(longName, workspaceId: _ws);

      expect(result.isInvalid, isTrue);
      expect(result.failures.length, greaterThanOrEqualTo(2));
    });
  });
}
