import 'package:feature_finance/src/data/mappers/money_minor_units_converter.dart';
import 'package:feature_finance/src/data/models/transaction_row.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';

/// Converts between the domain [Transaction] entity and the persistence
/// [TransactionRow] model. Pure conversion only — no validation, no
/// repository calls, no SQL, no business rules.
///
/// [Transaction] never represents a soft-deleted row: [TransactionDao]'s
/// read methods already exclude soft-deleted rows (`deleted_at IS NULL`), so
/// a domain [Transaction] instance can never have been loaded from a deleted
/// row in the first place. Consequently [toRow] always sets
/// [TransactionRow.deletedAt] to `null` — the only value that can ever be
/// correct for a live domain entity. Soft-deleting a row is performed
/// directly via `TransactionDao.softDelete`, never through this mapper.
final class TransactionMapper {
  const TransactionMapper();

  /// Converts a persisted [TransactionRow] to a domain [Transaction].
  ///
  /// Throws [FinanceException] if [TransactionRow.transactionType] does not
  /// correspond to a value this mapper recognizes, or if
  /// [TransactionRow.payee] is present but empty (the [Payee] VO rejects
  /// empty names) — corrupted or unsupported persisted data must fail
  /// loudly rather than be silently coerced.
  Transaction toEntity(TransactionRow row) {
    final currency = CurrencyCode(row.currency);
    final amount = MoneyMinorUnitsConverter.fromMinorUnits(
      row.amountMinor,
      row.currency,
    );

    return Transaction(
      id: TransactionId(row.transactionId),
      workspaceId: row.workspaceId,
      accountId: AccountId(row.accountId),
      type: _transactionTypeFromColumnValue(row.transactionType),
      amount: Money(amount: amount, currency: currency),
      categoryId: row.categoryId == null ? null : CategoryId(row.categoryId!),
      payee: row.payee == null ? null : Payee(row.payee!),
      note: row.note,
      date: TransactionDate(row.transactionDate),
      transferCounterpartId:
          row.transferPairId == null ? null : TransactionId(row.transferPairId!),
      attachmentIds: row.attachmentIds,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Transaction] to a persistable [TransactionRow].
  TransactionRow toRow(Transaction transaction) {
    return TransactionRow(
      transactionId: transaction.id.value,
      workspaceId: transaction.workspaceId,
      accountId: transaction.accountId.value,
      transferPairId: transaction.transferCounterpartId?.value,
      categoryId: transaction.categoryId?.value,
      amountMinor: MoneyMinorUnitsConverter.toMinorUnits(
        transaction.amount.amount,
        transaction.amount.currency.value,
      ),
      currency: transaction.amount.currency.value,
      transactionDate: transaction.date.value,
      transactionType: transaction.type.name,
      payee: transaction.payee?.value,
      note: transaction.note,
      attachmentIds: transaction.attachmentIds,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      deletedAt: null,
    );
  }

  TransactionType _transactionTypeFromColumnValue(String value) {
    for (final type in TransactionType.values) {
      if (type.name == value) return type;
    }
    throw FinanceException(
      message: 'Unrecognized transaction_type value persisted: "$value"',
    );
  }
}
