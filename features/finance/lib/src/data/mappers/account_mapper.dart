import 'package:feature_finance/src/data/mappers/money_minor_units_converter.dart';
import 'package:feature_finance/src/data/models/account_row.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';

/// Converts between the domain [Account] entity and the persistence
/// [AccountRow] model. Pure conversion only — no validation, no repository
/// calls, no SQL, no business rules.
///
/// [Account] never represents a soft-deleted row: [AccountDao]'s read
/// methods already exclude soft-deleted rows (`deleted_at IS NULL`), so a
/// domain [Account] instance can never have been loaded from a deleted row
/// in the first place. Consequently [toRow] always sets
/// [AccountRow.deletedAt] to `null` — this is not "defaulting a missing
/// value", it is the only value that can ever be correct for a live domain
/// entity. Soft-deleting a row is performed directly via
/// `AccountDao.softDelete`, never through this mapper.
final class AccountMapper {
  const AccountMapper();

  /// Converts a persisted [AccountRow] to a domain [Account].
  ///
  /// Throws [FinanceException] if [AccountRow.accountType] or
  /// [AccountRow.currency] do not correspond to a value this mapper
  /// recognizes — corrupted or unsupported persisted data must fail loudly
  /// rather than be silently coerced.
  Account toEntity(AccountRow row) {
    final currency = CurrencyCode(row.currency);
    final amount = MoneyMinorUnitsConverter.fromMinorUnits(
      row.openingBalanceMinor,
      row.currency,
    );

    return Account(
      id: AccountId(row.accountId),
      workspaceId: row.workspaceId,
      name: row.name,
      type: _accountTypeFromColumnValue(row.accountType),
      currency: currency,
      initialBalance: Money(amount: amount, currency: currency),
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Account] to a persistable [AccountRow].
  AccountRow toRow(Account account) {
    return AccountRow(
      accountId: account.id.value,
      workspaceId: account.workspaceId,
      name: account.name,
      accountType: account.type.name,
      currency: account.currency.value,
      openingBalanceMinor: MoneyMinorUnitsConverter.toMinorUnits(
        account.initialBalance.amount,
        account.currency.value,
      ),
      isActive: account.isActive,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      deletedAt: null,
    );
  }

  AccountType _accountTypeFromColumnValue(String value) {
    for (final type in AccountType.values) {
      if (type.name == value) return type;
    }
    throw FinanceException(
      message: 'Unrecognized account_type value persisted: "$value"',
    );
  }
}
