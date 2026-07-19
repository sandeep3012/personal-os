import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:platform_core/platform_core.dart';

/// Creates both legs of a Transfer atomically.
///
/// A Transfer moves money from one Account to another within the same
/// Workspace. This service produces the debit/credit Transaction pair, which
/// the use case then persists atomically via
/// [ITransactionRepository.saveTransferPair].
///
/// Enforces DOC-031 Business Invariants:
/// - **Invariant 3** — transfer legs share the same amount and currency.
/// - **Invariant 4** — [fromAccountId] must differ from [toAccountId].
///
/// Transfer legs are typed as follows so that [BalanceCalculationService] can
/// apply the correct direction without needing external context:
/// - Debit leg: [TransactionType.expense] on [fromAccountId] — money leaves.
/// - Credit leg: [TransactionType.income] on [toAccountId] — money arrives.
final class TransferService {
  TransferService({required IdGenerator idGenerator})
      : _idGenerator = idGenerator;

  final IdGenerator _idGenerator;

  /// Creates and returns the `(debit, credit)` Transaction pair for a transfer.
  ///
  /// Both legs share [amount], [note], [date], and [workspaceId]. They
  /// reference each other via [Transaction.transferCounterpartId].
  ///
  /// Throws [FinanceException] when [fromAccountId] == [toAccountId].
  (Transaction debit, Transaction credit) createTransferPair({
    required AccountId fromAccountId,
    required AccountId toAccountId,
    required String workspaceId,
    required Money amount,
    required TransactionDate date,
    String? note,
  }) {
    if (fromAccountId == toAccountId) {
      throw const FinanceException(
        message: 'A transfer cannot be made from an account to itself.',
      );
    }

    final now = DateTime.now();
    final debitId = TransactionId(_idGenerator.generate());
    final creditId = TransactionId(_idGenerator.generate());

    final debit = Transaction(
      id: debitId,
      workspaceId: workspaceId,
      accountId: fromAccountId,
      type: TransactionType.expense,
      amount: amount,
      note: note,
      date: date,
      transferCounterpartId: creditId,
      createdAt: now,
      updatedAt: now,
    );

    final credit = Transaction(
      id: creditId,
      workspaceId: workspaceId,
      accountId: toAccountId,
      type: TransactionType.income,
      amount: amount,
      note: note,
      date: date,
      transferCounterpartId: debitId,
      createdAt: now,
      updatedAt: now,
    );

    return (debit, credit);
  }
}
