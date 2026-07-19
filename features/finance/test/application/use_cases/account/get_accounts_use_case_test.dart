import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');

Account _account(String id, {bool isActive = true}) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: 'ws-1',
    name: 'Account $id',
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
  late FakeAccountRepository repo;
  late GetAccountsUseCase useCase;

  setUp(() {
    repo = FakeAccountRepository();
    useCase = GetAccountsUseCase(accountRepository: repo);
  });

  group('GetAccountsUseCase', () {
    test('returns empty list when workspace has no accounts', () async {
      final result = await useCase.execute(
          const GetAccountsInput(workspaceId: 'ws-1'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all active accounts', () async {
      repo.seed([_account('a1'), _account('a2'), _account('a3')]);

      final result = await useCase.execute(
          const GetAccountsInput(workspaceId: 'ws-1'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(3));
    });

    test('excludes inactive accounts', () async {
      repo.seed([
        _account('a1'),
        _account('a2', isActive: false),
        _account('a3'),
      ]);

      final result = await useCase.execute(
          const GetAccountsInput(workspaceId: 'ws-1'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.map((a) => a.id.value),
          containsAll(['a1', 'a3']));
      expect(result.valueOrNull!.map((a) => a.id.value),
          isNot(contains('a2')));
    });

    test('returns only the active account when mixed', () async {
      repo.seed([_account('active'), _account('inactive', isActive: false)]);

      final result = await useCase.execute(
          const GetAccountsInput(workspaceId: 'ws-1'));

      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id.value, 'active');
    });
  });
}
