import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/finance_integration_container.dart';

// Exercises IAccountRepository end-to-end through the real composed stack:
// FinanceModule → ServiceRegistry → AccountRepository → AccountDao →
// AccountMapper → InMemoryFinanceDatabaseExecutor. No mocking of DAOs,
// mappers, or repositories — the repository is resolved from the container,
// never constructed manually.

Account _account({
  String id = 'acc-1',
  String workspaceId = 'ws-1',
  String name = 'Savings',
  AccountType type = AccountType.savings,
  String currency = 'INR',
  String openingBalance = '0',
  bool isActive = true,
}) {
  final cc = CurrencyCode(currency);
  final now = DateTime(2024, 1, 1, 10, 30);
  return Account(
    id: AccountId(id),
    workspaceId: workspaceId,
    name: name,
    type: type,
    currency: cc,
    initialBalance: Money(amount: Decimal.parse(openingBalance), currency: cc),
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FinanceIntegrationContainer container;

  setUp(() => container = FinanceIntegrationContainer());

  group('AccountRepository (resolved from FinanceModule) — CRUD', () {
    test('save() persists a new account, retrievable via findById', () async {
      final saveResult =
          await container.accountRepository.save(_account(id: 'acc-1'));
      expect(saveResult.isSuccess, isTrue);

      final findResult = await container.accountRepository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(findResult.isSuccess, isTrue);
      expect(findResult.valueOrNull, isNotNull);
      expect(findResult.valueOrNull!.name, 'Savings');
    });

    test('save() with an existing id updates in place rather than duplicating',
        () async {
      await container.accountRepository.save(_account(id: 'acc-1', name: 'Old'));
      await container.accountRepository.save(_account(id: 'acc-1', name: 'New'));

      final all = await container.accountRepository.findAll(workspaceId: 'ws-1');
      expect(all.valueOrNull, hasLength(1));
      expect(all.valueOrNull!.first.name, 'New');
    });

    test('findById returns null for a non-existent account', () async {
      final result = await container.accountRepository.findById(
        const AccountId('missing'),
        workspaceId: 'ws-1',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('findAll returns every account in the workspace, none from another',
        () async {
      await container.accountRepository.save(_account(id: 'acc-1'));
      await container.accountRepository.save(_account(id: 'acc-2'));
      await container.accountRepository.save(
        _account(id: 'acc-other-ws', workspaceId: 'ws-2'),
      );

      final result = await container.accountRepository.findAll(workspaceId: 'ws-1');
      expect(result.valueOrNull, hasLength(2));
      expect(
        result.valueOrNull!.map((a) => a.id.value),
        containsAll(['acc-1', 'acc-2']),
      );
    });

    test('findActive excludes inactive accounts', () async {
      await container.accountRepository.save(_account(id: 'acc-active'));
      await container.accountRepository
          .save(_account(id: 'acc-inactive', isActive: false));

      final result =
          await container.accountRepository.findActive(workspaceId: 'ws-1');
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const AccountId('acc-active'));
    });

    test('softDelete excludes the account from findAll and findActive',
        () async {
      await container.accountRepository.save(_account(id: 'acc-1'));

      final deleteResult = await container.accountRepository.softDelete(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(deleteResult.isSuccess, isTrue);

      final all = await container.accountRepository.findAll(workspaceId: 'ws-1');
      final active =
          await container.accountRepository.findActive(workspaceId: 'ws-1');
      final byId = await container.accountRepository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );

      expect(all.valueOrNull, isEmpty);
      expect(active.valueOrNull, isEmpty);
      expect(byId.valueOrNull, isNull);
    });

    test('softDelete is idempotent — succeeds again after already deleted',
        () async {
      await container.accountRepository.save(_account(id: 'acc-1'));
      await container.accountRepository
          .softDelete(const AccountId('acc-1'), workspaceId: 'ws-1');

      final second = await container.accountRepository
          .softDelete(const AccountId('acc-1'), workspaceId: 'ws-1');
      expect(second.isSuccess, isTrue);
    });

    test('repeated save/update lifecycle preserves the latest state', () async {
      final repo = container.accountRepository;
      await repo.save(_account(id: 'acc-1', name: 'v1', isActive: true));
      await repo.save(_account(id: 'acc-1', name: 'v2', isActive: true));
      await repo.save(_account(id: 'acc-1', name: 'v3', isActive: false));

      final result = await repo.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.name, 'v3');
      expect(result.valueOrNull!.isActive, isFalse);

      final all = await repo.findAll(workspaceId: 'ws-1');
      expect(all.valueOrNull, hasLength(1)); // never duplicated across saves
    });
  });

  group('AccountRepository — Money round-trip', () {
    test('zero opening balance round-trips exactly', () async {
      await container.accountRepository
          .save(_account(id: 'acc-1', openingBalance: '0'));
      final result = await container.accountRepository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.initialBalance.amount, Decimal.zero);
    });

    test('a large decimal opening balance round-trips without precision loss',
        () async {
      await container.accountRepository.save(
        _account(id: 'acc-1', openingBalance: '999999999999.99'),
      );
      final result = await container.accountRepository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(
        result.valueOrNull!.initialBalance.amount,
        Decimal.parse('999999999999.99'),
      );
    });

    test('a negative opening balance (credit card) round-trips correctly',
        () async {
      await container.accountRepository.save(_account(
        id: 'acc-1',
        type: AccountType.creditCard,
        openingBalance: '-2500.50',
      ));
      final result = await container.accountRepository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(
        result.valueOrNull!.initialBalance.amount,
        Decimal.parse('-2500.50'),
      );
    });
  });

  group('AccountRepository — AccountType enum round-trip', () {
    for (final type in AccountType.values) {
      test('${type.name} round-trips through save/findById', () async {
        await container.accountRepository
            .save(_account(id: 'acc-${type.name}', type: type));

        final result = await container.accountRepository.findById(
          AccountId('acc-${type.name}'),
          workspaceId: 'ws-1',
        );
        expect(result.valueOrNull!.type, type);
      });
    }
  });

  group('AccountRepository — Unicode', () {
    test('account name with Unicode/emoji content round-trips exactly',
        () async {
      const name = 'Café Épargne 儲蓄 💰';
      await container.accountRepository
          .save(_account(id: 'acc-1', name: name));

      final result = await container.accountRepository.findById(
        const AccountId('acc-1'),
        workspaceId: 'ws-1',
      );
      expect(result.valueOrNull!.name, name);
    });
  });
}
