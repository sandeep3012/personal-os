import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

Account _makeAccount({
  String id = 'acc-1',
  String workspaceId = 'ws-1',
  String name = 'Savings',
  AccountType type = AccountType.savings,
  String currency = 'INR',
  String initialAmount = '0',
  bool isActive = true,
}) {
  final code = CurrencyCode(currency);
  return Account(
    id: AccountId(id),
    workspaceId: workspaceId,
    name: name,
    type: type,
    currency: code,
    initialBalance: Money(
      amount: Decimal.parse(initialAmount),
      currency: code,
    ),
    isActive: isActive,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('Account', () {
    // ── Construction ────────────────────────────────────────────────────────

    test('constructs with valid fields', () {
      final account = _makeAccount();
      expect(account.name, 'Savings');
      expect(account.type, AccountType.savings);
      expect(account.isActive, isTrue);
    });

    // ── Invariant 1 — name must not be empty ────────────────────────────────

    test('rejects empty name (Invariant 1)', () {
      expect(
        () => _makeAccount(name: ''),
        throwsA(isA<FinanceException>()),
      );
    });

    test('accepts single-character name', () {
      expect(() => _makeAccount(name: 'X'), returnsNormally);
    });

    // ── Identity equality ────────────────────────────────────────────────────

    test('two accounts with the same id are equal', () {
      final a = _makeAccount(id: 'acc-1', name: 'Alpha');
      final b = _makeAccount(id: 'acc-1', name: 'Beta');
      expect(a, equals(b));
    });

    test('accounts with different ids are not equal', () {
      final a = _makeAccount(id: 'acc-1');
      final b = _makeAccount(id: 'acc-2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode based on id', () {
      final a = _makeAccount(id: 'acc-1');
      final b = _makeAccount(id: 'acc-1');
      expect(a.hashCode, b.hashCode);
    });

    // ── copyWith ────────────────────────────────────────────────────────────

    test('copyWith returns a new account with updated name', () {
      final original = _makeAccount(name: 'Old Name');
      final updated = original.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.id, original.id);
      expect(updated.type, original.type);
    });

    test('copyWith rejects empty name', () {
      final original = _makeAccount();
      expect(
        () => original.copyWith(name: ''),
        throwsA(isA<FinanceException>()),
      );
    });

    test('copyWith with no arguments produces an equivalent account', () {
      final original = _makeAccount();
      final copy = original.copyWith();
      expect(copy, equals(original));
      expect(copy.name, original.name);
    });

    test('copyWith can deactivate account', () {
      final active = _makeAccount(isActive: true);
      final inactive = active.copyWith(isActive: false);
      expect(inactive.isActive, isFalse);
    });

    // ── toString ─────────────────────────────────────────────────────────────

    test('toString includes id and name', () {
      final account = _makeAccount(id: 'acc-42', name: 'My Account');
      expect(account.toString(), contains('acc-42'));
      expect(account.toString(), contains('My Account'));
    });
  });
}
