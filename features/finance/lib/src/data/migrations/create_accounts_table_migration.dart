import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `accounts` table (DOC-031 §6.2) and its supporting indexes.
///
/// [Account.type] is a `TEXT` column constrained to the values of the actual
/// `AccountType` enum (`checking`, `savings`, `creditCard`, `cash`,
/// `investment` — see `account_type.dart`). Money is stored as
/// `INTEGER` minor units per DOC-031 §6.2; the domain `Money`/`Decimal`
/// conversion is a repository-layer concern (Sprint 8B Step 2).
///
/// Soft delete is represented by nullable [FinanceSchema.accountDeletedAt]
/// rather than a boolean flag, so the deletion moment is recoverable for
/// audit/debugging — the [Account] entity itself has no such field; this is
/// purely a storage-layer concern (see `account.dart`).
final class CreateAccountsTableMigration extends Migration {
  const CreateAccountsTableMigration() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${FinanceSchema.accountsTable} (
        ${FinanceSchema.accountId}                TEXT    PRIMARY KEY,
        ${FinanceSchema.accountWorkspaceId}        TEXT    NOT NULL,
        ${FinanceSchema.accountName}               TEXT    NOT NULL CHECK (length(trim(${FinanceSchema.accountName})) > 0),
        ${FinanceSchema.accountType}               TEXT    NOT NULL CHECK (${FinanceSchema.accountType} IN ('checking', 'savings', 'creditCard', 'cash', 'investment')),
        ${FinanceSchema.accountCurrency}           TEXT    NOT NULL CHECK (length(${FinanceSchema.accountCurrency}) = 3 AND ${FinanceSchema.accountCurrency} GLOB '[A-Z][A-Z][A-Z]'),
        ${FinanceSchema.accountOpeningBalanceMinor} INTEGER NOT NULL,
        ${FinanceSchema.accountIsActive}           INTEGER NOT NULL DEFAULT 1 CHECK (${FinanceSchema.accountIsActive} IN (0, 1)),
        ${FinanceSchema.accountCreatedAt}          TEXT    NOT NULL,
        ${FinanceSchema.accountUpdatedAt}          TEXT    NOT NULL,
        ${FinanceSchema.accountDeletedAt}          TEXT
      )
    ''');

    // Serves IAccountRepository.findAll(workspaceId) and general workspace scoping.
    await ctx.execute('''
      CREATE INDEX idx_accounts_workspace_id
      ON ${FinanceSchema.accountsTable} (${FinanceSchema.accountWorkspaceId})
    ''');

    // Serves IAccountRepository.findActive(workspaceId); excludes soft-deleted rows.
    await ctx.execute('''
      CREATE INDEX idx_accounts_workspace_active
      ON ${FinanceSchema.accountsTable} (${FinanceSchema.accountWorkspaceId}, ${FinanceSchema.accountIsActive})
      WHERE ${FinanceSchema.accountDeletedAt} IS NULL
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_accounts_workspace_active');
    await ctx.execute('DROP INDEX IF EXISTS idx_accounts_workspace_id');
    await ctx.execute('DROP TABLE IF EXISTS ${FinanceSchema.accountsTable}');
  }
}
