import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import 'support/finance_integration_container.dart';

// Exercises ITransactionRepository.saveTransferPair end-to-end, including
// genuine rollback: InMemoryFinanceTransactionRunner takes a real snapshot
// of table state and restores it on failure, so "no partial persistence"
// is proven by actually querying the store afterward — not by a call count.

final class _IdSeq {
  var _i = 0;
  String next() => 'txn-${++_i}';
}

void main() {
  late FinanceIntegrationContainer container;
  late TransferService transferService;

  setUp(() {
    container = FinanceIntegrationContainer();
    transferService = TransferService(idGenerator: _SeqIdGenerator());
  });

  (Transaction debit, Transaction credit) buildPair({
    String from = 'acc-from',
    String to = 'acc-to',
    String amount = '1000',
    String currency = 'INR',
  }) {
    final cc = CurrencyCode(currency);
    return transferService.createTransferPair(
      fromAccountId: AccountId(from),
      toAccountId: AccountId(to),
      workspaceId: 'ws-1',
      amount: Money(amount: Decimal.parse(amount), currency: cc),
      date: TransactionDate(DateTime(2024, 6, 15)),
    );
  }

  group('saveTransferPair — success path', () {
    test('both transactions are persisted and independently findable',
        () async {
      final (debit, credit) = buildPair();

      final result =
          await container.transactionRepository.saveTransferPair(debit, credit);
      expect(result.isSuccess, isTrue);

      final foundDebit = await container.transactionRepository.findById(
        debit.id,
        workspaceId: 'ws-1',
      );
      final foundCredit = await container.transactionRepository.findById(
        credit.id,
        workspaceId: 'ws-1',
      );
      expect(foundDebit.valueOrNull, isNotNull);
      expect(foundCredit.valueOrNull, isNotNull);
    });

    test('counterpart ids are preserved on both persisted legs', () async {
      final (debit, credit) = buildPair();
      await container.transactionRepository.saveTransferPair(debit, credit);

      final foundDebit = await container.transactionRepository.findById(
        debit.id,
        workspaceId: 'ws-1',
      );
      final foundCredit = await container.transactionRepository.findById(
        credit.id,
        workspaceId: 'ws-1',
      );

      expect(foundDebit.valueOrNull!.transferCounterpartId, credit.id);
      expect(foundCredit.valueOrNull!.transferCounterpartId, debit.id);
    });

    test('debit leg is an expense on the source account; credit leg is '
        'income on the destination account', () async {
      final (debit, credit) = buildPair();
      await container.transactionRepository.saveTransferPair(debit, credit);

      final foundDebit = await container.transactionRepository.findById(
        debit.id,
        workspaceId: 'ws-1',
      );
      final foundCredit = await container.transactionRepository.findById(
        credit.id,
        workspaceId: 'ws-1',
      );

      expect(foundDebit.valueOrNull!.type, TransactionType.expense);
      expect(foundDebit.valueOrNull!.accountId, const AccountId('acc-from'));
      expect(foundCredit.valueOrNull!.type, TransactionType.income);
      expect(foundCredit.valueOrNull!.accountId, const AccountId('acc-to'));
    });

    test('findTransferPair-equivalent: querying by account surfaces both legs',
        () async {
      final (debit, credit) = buildPair();
      await container.transactionRepository.saveTransferPair(debit, credit);

      final fromLegs = await container.transactionRepository.findByAccount(
        const AccountId('acc-from'),
        workspaceId: 'ws-1',
      );
      final toLegs = await container.transactionRepository.findByAccount(
        const AccountId('acc-to'),
        workspaceId: 'ws-1',
      );

      expect(fromLegs.valueOrNull, hasLength(1));
      expect(toLegs.valueOrNull, hasLength(1));
    });

    test('both legs share the same amount and currency', () async {
      final (debit, credit) = buildPair(amount: '750.50');
      await container.transactionRepository.saveTransferPair(debit, credit);

      final foundDebit = await container.transactionRepository.findById(
        debit.id,
        workspaceId: 'ws-1',
      );
      final foundCredit = await container.transactionRepository.findById(
        credit.id,
        workspaceId: 'ws-1',
      );

      expect(foundDebit.valueOrNull!.amount.amount, Decimal.parse('750.50'));
      expect(foundCredit.valueOrNull!.amount.amount, Decimal.parse('750.50'));
    });
  });

  group('saveTransferPair — atomicity and rollback', () {
    test('rollback on second-insert failure leaves no partial persistence',
        () async {
      final (debit, credit) = buildPair();

      container.executor
        ..insertError = Exception('disk full on second insert')
        ..throwOnInsertCallIndex = 1; // second insert (credit leg) fails

      final result =
          await container.transactionRepository.saveTransferPair(debit, credit);

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());

      // Prove no partial persistence by querying the real store afterward —
      // neither leg should be findable, not even the debit that was
      // inserted before the failure.
      final foundDebit = await container.transactionRepository.findById(
        debit.id,
        workspaceId: 'ws-1',
      );
      final foundCredit = await container.transactionRepository.findById(
        credit.id,
        workspaceId: 'ws-1',
      );
      expect(foundDebit.valueOrNull, isNull);
      expect(foundCredit.valueOrNull, isNull);
    });

    test('rollback on first-insert failure leaves no partial persistence',
        () async {
      final (debit, credit) = buildPair();

      container.executor
        ..insertError = Exception('disk full on first insert')
        ..throwOnInsertCallIndex = 0;

      final result =
          await container.transactionRepository.saveTransferPair(debit, credit);

      expect(result.isFailure, isTrue);

      final foundDebit = await container.transactionRepository.findById(
        debit.id,
        workspaceId: 'ws-1',
      );
      expect(foundDebit.valueOrNull, isNull);
    });

    test('commit is recorded exactly once on success, rollback never fires',
        () async {
      final (debit, credit) = buildPair();
      await container.transactionRepository.saveTransferPair(debit, credit);

      expect(container.runner.beginCount, 1);
      expect(container.runner.commitCount, 1);
      expect(container.runner.rollbackCount, 0);
    });

    test('rollback is recorded exactly once on failure, commit never fires',
        () async {
      final (debit, credit) = buildPair();
      container.executor
        ..insertError = Exception('boom')
        ..throwOnInsertCallIndex = 1;

      await container.transactionRepository.saveTransferPair(debit, credit);

      expect(container.runner.beginCount, 1);
      expect(container.runner.commitCount, 0);
      expect(container.runner.rollbackCount, 1);
    });

    test('a successful transfer does not affect unrelated, previously '
        'persisted transactions (no collateral rollback)', () async {
      // Seed an unrelated transaction before the transfer.
      await container.transactionRepository.save(Transaction(
        id: const TransactionId('unrelated'),
        workspaceId: 'ws-1',
        accountId: const AccountId('acc-other'),
        type: TransactionType.income,
        amount: Money(amount: Decimal.parse('50'), currency: CurrencyCode('INR')),
        date: TransactionDate(DateTime(2024, 1, 1)),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      final (debit, credit) = buildPair();
      await container.transactionRepository.saveTransferPair(debit, credit);

      final unrelated = await container.transactionRepository.findById(
        const TransactionId('unrelated'),
        workspaceId: 'ws-1',
      );
      expect(unrelated.valueOrNull, isNotNull);
    });

    test('after a failed transfer, an unrelated previously persisted '
        'transaction survives the rollback intact', () async {
      await container.transactionRepository.save(Transaction(
        id: const TransactionId('unrelated'),
        workspaceId: 'ws-1',
        accountId: const AccountId('acc-other'),
        type: TransactionType.income,
        amount: Money(amount: Decimal.parse('50'), currency: CurrencyCode('INR')),
        date: TransactionDate(DateTime(2024, 1, 1)),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      final (debit, credit) = buildPair();
      container.executor
        ..insertError = Exception('boom')
        ..throwOnInsertCallIndex = 1;
      await container.transactionRepository.saveTransferPair(debit, credit);

      final unrelated = await container.transactionRepository.findById(
        const TransactionId('unrelated'),
        workspaceId: 'ws-1',
      );
      expect(unrelated.valueOrNull, isNotNull);
      expect(unrelated.valueOrNull!.amount.amount, Decimal.parse('50'));
    });
  });
}

final class _SeqIdGenerator implements IdGenerator {
  final _seq = _IdSeq();
  @override
  String generate() => _seq.next();
}
