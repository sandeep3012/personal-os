import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/update_account_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_updated_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');

Account _account(String id, {String name = 'Old Name', bool isActive = true}) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: 'ws-1',
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
  late FakeAccountRepository repo;
  late UpdateAccountUseCase useCase;

  setUp(() {
    repo = FakeAccountRepository();
    useCase = UpdateAccountUseCase(
      accountRepository: repo,
      specification: AccountCanBeUpdatedSpecification(accountRepository: repo),
    );
  });

  group('UpdateAccountUseCase', () {
    test('updates name when provided', () async {
      repo.seed([_account('acc-1')]);

      final result = await useCase.execute(const UpdateAccountInput(
        accountId: AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: 'New Name',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'New Name');
    });

    test('keeps existing name when name is null', () async {
      repo.seed([_account('acc-1', name: 'Keep Me')]);

      final result = await useCase.execute(const UpdateAccountInput(
        accountId: AccountId('acc-1'),
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'Keep Me');
    });

    test('deactivates account when isActive is false', () async {
      repo.seed([_account('acc-1')]);

      final result = await useCase.execute(const UpdateAccountInput(
        accountId: AccountId('acc-1'),
        workspaceId: 'ws-1',
        isActive: false,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.isActive, isFalse);
    });

    test('persists the updated account', () async {
      repo.seed([_account('acc-1', name: 'Old')]);

      await useCase.execute(const UpdateAccountInput(
        accountId: AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: 'New',
      ));

      expect(repo.store.first.name, 'New');
    });

    test('fails with FinanceException when account not found', () async {
      final result = await useCase.execute(const UpdateAccountInput(
        accountId: AccountId('missing'),
        workspaceId: 'ws-1',
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });

    // ── Specification integration ─────────────────────────────────────────────

    test('fails when new name is empty and repository save is never reached',
        () async {
      repo.seed([_account('acc-1', name: 'Original')]);

      final result = await useCase.execute(const UpdateAccountInput(
        accountId: AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: '',
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      // The original account must be untouched — save() was never called.
      expect(repo.store.first.name, 'Original');
    });

    test('fails when new name exceeds 100 characters (oversized name rejection)',
        () async {
      repo.seed([_account('acc-1', name: 'Original')]);
      final longName = 'A' * 101;

      final result = await useCase.execute(UpdateAccountInput(
        accountId: const AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: longName,
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(
        (result.exceptionOrNull as FinanceException).message,
        contains('100 characters'),
      );
      expect(repo.store.first.name, 'Original');
    });

    test('is satisfied and persists when name is exactly 100 characters',
        () async {
      repo.seed([_account('acc-1')]);
      final name100 = 'A' * 100;

      final result = await useCase.execute(UpdateAccountInput(
        accountId: const AccountId('acc-1'),
        workspaceId: 'ws-1',
        name: name100,
      ));

      expect(result.isSuccess, isTrue);
      expect(repo.store.first.name, name100);
    });
  });
}
