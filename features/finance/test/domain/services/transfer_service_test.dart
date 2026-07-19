import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

// ── Deterministic ID generator for tests ─────────────────────────────────────

final class _SequentialIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String generate() => 'txn-${++_counter}';
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');

Money _money(String amount) =>
    Money(amount: Decimal.parse(amount), currency: _inr);

const _from = AccountId('from-acc');
const _to = AccountId('to-acc');
final _date = TransactionDate(DateTime(2024, 6, 15));
const _workspace = 'ws-1';

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late TransferService service;

  setUp(() => service = TransferService(idGenerator: _SequentialIdGenerator()));

  group('TransferService', () {
    test('throws FinanceException when fromAccountId equals toAccountId', () {
      expect(
        () => service.createTransferPair(
          fromAccountId: _from,
          toAccountId: _from,
          workspaceId: _workspace,
          amount: _money('500'),
          date: _date,
        ),
        throwsA(isA<FinanceException>()),
      );
    });

    test('debit leg has type expense and belongs to fromAccountId', () {
      final (debit, _) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('500'),
        date: _date,
      );

      expect(debit.type, TransactionType.expense);
      expect(debit.accountId, _from);
    });

    test('credit leg has type income and belongs to toAccountId', () {
      final (_, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('500'),
        date: _date,
      );

      expect(credit.type, TransactionType.income);
      expect(credit.accountId, _to);
    });

    test('debit transferCounterpartId points to credit id', () {
      final (debit, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('500'),
        date: _date,
      );

      expect(debit.transferCounterpartId, credit.id);
    });

    test('credit transferCounterpartId points to debit id', () {
      final (debit, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('500'),
        date: _date,
      );

      expect(credit.transferCounterpartId, debit.id);
    });

    test('both legs carry the same amount and currency', () {
      final amount = _money('1250.50');
      final (debit, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: amount,
        date: _date,
      );

      expect(debit.amount, amount);
      expect(credit.amount, amount);
    });

    test('both legs share the same workspaceId', () {
      final (debit, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('100'),
        date: _date,
      );

      expect(debit.workspaceId, _workspace);
      expect(credit.workspaceId, _workspace);
    });

    test('note is set on both legs when provided', () {
      final (debit, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('100'),
        date: _date,
        note: 'rent transfer',
      );

      expect(debit.note, 'rent transfer');
      expect(credit.note, 'rent transfer');
    });

    test('note is null on both legs when omitted', () {
      final (debit, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('100'),
        date: _date,
      );

      expect(debit.note, isNull);
      expect(credit.note, isNull);
    });

    test('debit and credit have distinct transaction ids', () {
      final (debit, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('100'),
        date: _date,
      );

      expect(debit.id, isNot(credit.id));
    });

    test('both legs carry the same date', () {
      final (debit, credit) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('100'),
        date: _date,
      );

      expect(debit.date, _date);
      expect(credit.date, _date);
    });

    test('successive calls produce unique ids', () {
      final (d1, c1) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('100'),
        date: _date,
      );
      final (d2, c2) = service.createTransferPair(
        fromAccountId: _from,
        toAccountId: _to,
        workspaceId: _workspace,
        amount: _money('200'),
        date: _date,
      );

      final ids = {d1.id, c1.id, d2.id, c2.id};
      expect(ids.length, 4);
    });
  });
}
