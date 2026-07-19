import 'package:feature_finance/src/data/schema/finance_schema.dart';

/// A single, unmapped row from the `accounts` table.
///
/// [AccountRow] is a persistence-layer data shape only — it has no business
/// methods, no validation, and no relationship to the domain `Account`
/// entity. Mapping between [AccountRow] and `Account` is a repository-layer
/// concern (Sprint 8B Step 3), not a DAO concern.
final class AccountRow {
  const AccountRow({
    required this.accountId,
    required this.workspaceId,
    required this.name,
    required this.accountType,
    required this.currency,
    required this.openingBalanceMinor,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String accountId;
  final String workspaceId;
  final String name;
  final String accountType;
  final String currency;
  final int openingBalanceMinor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Builds an [AccountRow] from a raw SQL result row.
  factory AccountRow.fromMap(Map<String, Object?> map) {
    final deletedAtValue = map[FinanceSchema.accountDeletedAt] as String?;
    return AccountRow(
      accountId: map[FinanceSchema.accountId]! as String,
      workspaceId: map[FinanceSchema.accountWorkspaceId]! as String,
      name: map[FinanceSchema.accountName]! as String,
      accountType: map[FinanceSchema.accountType]! as String,
      currency: map[FinanceSchema.accountCurrency]! as String,
      openingBalanceMinor: map[FinanceSchema.accountOpeningBalanceMinor]! as int,
      isActive: (map[FinanceSchema.accountIsActive]! as int) == 1,
      createdAt: DateTime.parse(map[FinanceSchema.accountCreatedAt]! as String),
      updatedAt: DateTime.parse(map[FinanceSchema.accountUpdatedAt]! as String),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [FinanceSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        FinanceSchema.accountId: accountId,
        FinanceSchema.accountWorkspaceId: workspaceId,
        FinanceSchema.accountName: name,
        FinanceSchema.accountType: accountType,
        FinanceSchema.accountCurrency: currency,
        FinanceSchema.accountOpeningBalanceMinor: openingBalanceMinor,
        FinanceSchema.accountIsActive: isActive ? 1 : 0,
        FinanceSchema.accountCreatedAt: createdAt.toIso8601String(),
        FinanceSchema.accountUpdatedAt: updatedAt.toIso8601String(),
        FinanceSchema.accountDeletedAt: deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.accountId == accountId &&
          other.workspaceId == workspaceId &&
          other.name == name &&
          other.accountType == accountType &&
          other.currency == currency &&
          other.openingBalanceMinor == openingBalanceMinor &&
          other.isActive == isActive &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        accountId,
        workspaceId,
        name,
        accountType,
        currency,
        openingBalanceMinor,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'AccountRow(accountId: $accountId, name: $name)';
}
