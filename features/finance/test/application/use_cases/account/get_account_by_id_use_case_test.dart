import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_by_id_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';

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

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository repo;
  late GetAccountByIdUseCase useCase;

  setUp(() {
    repo = FakeAccountRepository();
    useCase = GetAccountByIdUseCase(accountRepository: repo);
  });

  group('GetAccountByIdUseCase', () {
    test('returns the account when found', () async {
      repo.seed([_account('acc-1')]);

      final result = await useCase.execute(const GetAccountByIdInput(
        accountId: AccountId('acc-1'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.id.value, 'acc-1');
    });

    test('fails with FinanceException when account does not exist', () async {
      final result = await useCase.execute(const GetAccountByIdInput(
        accountId: AccountId('missing'),
        workspaceId: 'ws-1',
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });

    test('returns correct account when multiple accounts exist', () async {
      repo.seed([_account('acc-1'), _account('acc-2'), _account('acc-3')]);

      final result = await useCase.execute(const GetAccountByIdInput(
        accountId: AccountId('acc-2'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.id.value, 'acc-2');
    });
  });
}
