import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── AccountId ─────────────────────────────────────────────────────────────

  group('AccountId', () {
    const id = AccountId('acc-001');

    test('stores value', () => expect(id.value, 'acc-001'));

    test('equality by value', () {
      expect(const AccountId('x'), equals(const AccountId('x')));
    });

    test('inequality for different values', () {
      expect(const AccountId('x'), isNot(equals(const AccountId('y'))));
    });

    test('hash consistent with equality', () {
      expect(
        const AccountId('x').hashCode,
        equals(const AccountId('x').hashCode),
      );
    });

    test('toString returns raw value', () {
      expect(id.toString(), 'acc-001');
    });

    test('AccountId and TransactionId with same string are not equal', () {
      const accountId = AccountId('shared');
      const transactionId = TransactionId('shared');
      expect(accountId, isNot(equals(transactionId)));
    });
  });

  // ── TransactionId ─────────────────────────────────────────────────────────

  group('TransactionId', () {
    const id = TransactionId('txn-001');

    test('stores value', () => expect(id.value, 'txn-001'));

    test('equality by value', () {
      expect(const TransactionId('x'), equals(const TransactionId('x')));
    });

    test('inequality for different values', () {
      expect(const TransactionId('x'), isNot(equals(const TransactionId('y'))));
    });

    test('hash consistent with equality', () {
      expect(
        const TransactionId('x').hashCode,
        equals(const TransactionId('x').hashCode),
      );
    });

    test('toString returns raw value', () {
      expect(id.toString(), 'txn-001');
    });
  });

  // ── CategoryId ────────────────────────────────────────────────────────────

  group('CategoryId', () {
    const id = CategoryId('cat-groceries');

    test('stores value', () => expect(id.value, 'cat-groceries'));

    test('equality by value', () {
      expect(const CategoryId('x'), equals(const CategoryId('x')));
    });

    test('inequality for different values', () {
      expect(const CategoryId('x'), isNot(equals(const CategoryId('y'))));
    });

    test('hash consistent with equality', () {
      expect(
        const CategoryId('x').hashCode,
        equals(const CategoryId('x').hashCode),
      );
    });

    test('toString returns raw value', () {
      expect(id.toString(), 'cat-groceries');
    });
  });

  // ── AccountType ───────────────────────────────────────────────────────────

  group('AccountType', () {
    test('has expected values', () {
      expect(AccountType.values, hasLength(5));
      expect(
        AccountType.values,
        containsAll([
          AccountType.checking,
          AccountType.savings,
          AccountType.creditCard,
          AccountType.cash,
          AccountType.investment,
        ]),
      );
    });

    test('can be compared by identity', () {
      expect(AccountType.checking, AccountType.checking);
      expect(AccountType.checking, isNot(AccountType.savings));
    });

    test('name property is correct', () {
      expect(AccountType.creditCard.name, 'creditCard');
      expect(AccountType.checking.name, 'checking');
    });
  });

  // ── TransactionType ───────────────────────────────────────────────────────

  group('TransactionType', () {
    test('has expected values', () {
      expect(TransactionType.values, hasLength(3));
      expect(
        TransactionType.values,
        containsAll([
          TransactionType.income,
          TransactionType.expense,
          TransactionType.transfer,
        ]),
      );
    });

    test('can be compared by identity', () {
      expect(TransactionType.income, TransactionType.income);
      expect(TransactionType.income, isNot(TransactionType.expense));
    });

    test('name property is correct', () {
      expect(TransactionType.expense.name, 'expense');
      expect(TransactionType.transfer.name, 'transfer');
    });
  });
}
