import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/transaction/get_transactions_by_account_use_case.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../../../helpers/fake_transaction_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');
const _accA = AccountId('acc-a');
const _accB = AccountId('acc-b');

Transaction _txn(String id, AccountId accountId, DateTime date) {
  return Transaction(
    id: TransactionId(id),
    workspaceId: 'ws-1',
    accountId: accountId,
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse('100'), currency: _inr),
    date: TransactionDate(date),
    createdAt: date,
    updatedAt: date,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeTransactionRepository repo;
  late GetTransactionsByAccountUseCase useCase;

  setUp(() {
    repo = FakeTransactionRepository();
    useCase = GetTransactionsByAccountUseCase(transactionRepository: repo);
  });

  group('GetTransactionsByAccountUseCase', () {
    test('returns all transactions for the account', () async {
      repo.seed([
        _txn('t1', _accA, DateTime(2024, 6, 10)),
        _txn('t2', _accA, DateTime(2024, 6, 20)),
        _txn('t3', _accB, DateTime(2024, 6, 15)),
      ]);

      final result = await useCase.execute(const GetTransactionsByAccountInput(
        accountId: _accA,
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(2));
    });

    test('returns empty list when account has no transactions', () async {
      final result = await useCase.execute(const GetTransactionsByAccountInput(
        accountId: _accA,
        workspaceId: 'ws-1',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('filters by dateRange when provided', () async {
      repo.seed([
        _txn('t1', _accA, DateTime(2024, 5, 31)),
        _txn('t2', _accA, DateTime(2024, 6, 15)),
        _txn('t3', _accA, DateTime(2024, 7, 1)),
      ]);

      final result = await useCase.execute(GetTransactionsByAccountInput(
        accountId: _accA,
        workspaceId: 'ws-1',
        dateRange: DateRange(
          start: DateTime(2024, 6, 1),
          end: DateTime(2024, 6, 30),
        ),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id.value, 't2');
    });

    test('excludes transactions from other accounts', () async {
      repo.seed([_txn('t1', _accB, DateTime(2024, 6, 1))]);

      final result = await useCase.execute(const GetTransactionsByAccountInput(
        accountId: _accA,
        workspaceId: 'ws-1',
      ));

      expect(result.valueOrNull, isEmpty);
    });
  });
}
