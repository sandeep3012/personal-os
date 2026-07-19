import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/data/mappers/account_mapper.dart';
import 'package:feature_finance/src/data/models/account_row.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = AccountMapper();

  Account account({
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
      updatedAt: DateTime(2024, 2, 1, 8),
    );
  }

  group('AccountMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(account(id: 'acc-1', workspaceId: 'ws-1'));

      expect(row.accountId, 'acc-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.name, 'Savings');
      expect(row.accountType, 'savings');
      expect(row.currency, 'INR');
      expect(row.isActive, isTrue);
    });

    test('converts Money to minor units via the centralized converter', () {
      final row = mapper.toRow(account(openingBalance: '1250.75'));
      expect(row.openingBalanceMinor, 125075);
    });

    test('converts zero opening balance to 0 minor units', () {
      final row = mapper.toRow(account(openingBalance: '0'));
      expect(row.openingBalanceMinor, 0);
    });

    test('converts a negative opening balance (credit card) without error', () {
      final row = mapper.toRow(account(
        type: AccountType.creditCard,
        openingBalance: '-2500.50',
      ));
      expect(row.openingBalanceMinor, -250050);
    });

    test('converts a very large opening balance without precision loss', () {
      final row = mapper.toRow(account(openingBalance: '999999999999.99'));
      expect(row.openingBalanceMinor, 99999999999999);
    });

    test('preserves createdAt and updatedAt exactly', () {
      final now = DateTime(2024, 1, 1, 10, 30);
      final updated = DateTime(2024, 2, 1, 8);
      final row = mapper.toRow(account());

      expect(row.createdAt, now);
      expect(row.updatedAt, updated);
    });

    test('always maps deletedAt to null (domain Account is never soft-deleted)',
        () {
      final row = mapper.toRow(account());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode account names', () {
      final row = mapper.toRow(account(name: 'Café Épargne 儲蓄 💰'));
      expect(row.name, 'Café Épargne 儲蓄 💰');
    });

    test('maps every AccountType to its enum name', () {
      for (final type in AccountType.values) {
        final row = mapper.toRow(account(type: type));
        expect(row.accountType, type.name);
      }
    });

    test('maps every registered currency correctly', () {
      for (final currency in ['USD', 'INR', 'EUR', 'JPY', 'BHD']) {
        final row = mapper.toRow(account(currency: currency));
        expect(row.currency, currency);
      }
    });
  });

  group('AccountMapper.toEntity', () {
    AccountRow row({
      String id = 'acc-1',
      String workspaceId = 'ws-1',
      String name = 'Savings',
      String type = 'savings',
      String currency = 'INR',
      int openingBalanceMinor = 0,
      bool isActive = true,
      DateTime? deletedAt,
    }) {
      final now = DateTime(2024, 1, 1, 10, 30);
      return AccountRow(
        accountId: id,
        workspaceId: workspaceId,
        name: name,
        accountType: type,
        currency: currency,
        openingBalanceMinor: openingBalanceMinor,
        isActive: isActive,
        createdAt: now,
        updatedAt: DateTime(2024, 2, 1, 8),
        deletedAt: deletedAt,
      );
    }

    test('maps all scalar fields', () {
      final account = mapper.toEntity(row(id: 'acc-2', name: 'Checking'));

      expect(account.id, const AccountId('acc-2'));
      expect(account.workspaceId, 'ws-1');
      expect(account.name, 'Checking');
      expect(account.isActive, isTrue);
    });

    test('converts minor units back to Decimal Money', () {
      final account = mapper.toEntity(row(openingBalanceMinor: 12575));
      expect(account.initialBalance.amount, Decimal.parse('125.75'));
      expect(account.initialBalance.currency.value, 'INR');
    });

    test('converts zero minor units to zero Decimal', () {
      final account = mapper.toEntity(row(openingBalanceMinor: 0));
      expect(account.initialBalance.amount, Decimal.zero);
    });

    test('converts a negative minor-unit balance', () {
      final account =
          mapper.toEntity(row(type: 'creditCard', openingBalanceMinor: -250050));
      expect(account.initialBalance.amount, Decimal.parse('-2500.50'));
    });

    test('converts every AccountType column value back to its enum', () {
      for (final type in AccountType.values) {
        final account = mapper.toEntity(row(type: type.name));
        expect(account.type, type);
      }
    });

    test('throws FinanceException for an unrecognized account_type value', () {
      expect(
        () => mapper.toEntity(row(type: 'not_a_real_type')),
        throwsA(isA<FinanceException>()),
      );
    });

    test('ignores deletedAt on the row (Account has no such field)', () {
      final account = mapper.toEntity(row(deletedAt: DateTime(2024, 3, 1)));
      // No compile-time way to read deletedAt off Account — this proves it
      // maps without throwing regardless of the row's soft-delete state.
      expect(account.name, 'Savings');
    });

    test('preserves Unicode account names', () {
      final account = mapper.toEntity(row(name: 'Épargne 儲蓄 💰'));
      expect(account.name, 'Épargne 儲蓄 💰');
    });
  });

  group('AccountMapper round-trip', () {
    test('Account -> AccountRow -> Account preserves all domain fields', () {
      final original = account(
        id: 'acc-rt',
        workspaceId: 'ws-rt',
        name: 'Round Trip',
        type: AccountType.investment,
        currency: 'USD',
        openingBalance: '4999.42',
        isActive: false,
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.currency.value, original.currency.value);
      expect(restored.initialBalance.amount, original.initialBalance.amount);
      expect(restored.isActive, original.isActive);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trip is exact for a zero-decimal currency (JPY)', () {
      final original = account(currency: 'JPY', openingBalance: '5000');
      final restored = mapper.toEntity(mapper.toRow(original));
      expect(restored.initialBalance.amount, Decimal.parse('5000'));
    });

    test('round-trip is exact for a three-decimal currency (BHD)', () {
      final original = account(currency: 'BHD', openingBalance: '12.345');
      final restored = mapper.toEntity(mapper.toRow(original));
      expect(restored.initialBalance.amount, Decimal.parse('12.345'));
    });
  });
}
