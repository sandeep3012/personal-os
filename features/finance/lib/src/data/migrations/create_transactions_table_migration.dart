import 'package:feature_finance/src/data/schema/finance_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `transactions` table (DOC-031 §6.2) and its supporting indexes.
///
/// Must run after [CreateAccountsTableMigration] (version 1) — this migration
/// is version 2 — because [FinanceSchema.transactionAccountId] carries a
/// foreign key to `accounts`.
///
/// [FinanceSchema.transactionAttachmentIds] stores a JSON-encoded array of
/// opaque platform attachment references (`Transaction.attachmentIds` in
/// `transaction.dart`). This column is not present in DOC-031 §6.2's
/// example schema but is required because it is a real field on the
/// [Transaction] entity — the domain model, not the doc's illustrative
/// table, is the source of truth for this step.
///
/// `ON DELETE RESTRICT` on [FinanceSchema.transactionAccountId] exists only
/// as a defensive schema-level guard. The application never issues a hard
/// `DELETE` — all deletion goes through `ITransactionRepository.softDelete`
/// (an `UPDATE ... SET deleted_at = ...`) — so it is not expected to trigger
/// in normal operation.
///
/// [FinanceSchema.transactionTransferPairId] is intentionally a plain column
/// with no foreign key (Sprint 8B Step 1.6 architecture review). A
/// self-referencing FK would force `saveTransferPair(debit, credit)` to
/// resolve a mutual-reference insert-order problem (each row references the
/// other's not-yet-existing primary key). Referential integrity for the pair
/// is instead guaranteed by `saveTransferPair`'s single atomic DB transaction
/// (DOC-031 R3) and the fact that deletion is always soft — the referenced
/// row can never be physically removed, so the column can never dangle. A
/// `CHECK` constraint still guards against a row nonsensically pointing at
/// itself.
final class CreateTransactionsTableMigration extends Migration {
  const CreateTransactionsTableMigration() : super(version: 2);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${FinanceSchema.transactionsTable} (
        ${FinanceSchema.transactionId}             TEXT    PRIMARY KEY,
        ${FinanceSchema.transactionWorkspaceId}     TEXT    NOT NULL,
        ${FinanceSchema.transactionAccountId}       TEXT    NOT NULL REFERENCES ${FinanceSchema.accountsTable}(${FinanceSchema.accountId}) ON DELETE RESTRICT,
        ${FinanceSchema.transactionTransferPairId}  TEXT    NULL CHECK (${FinanceSchema.transactionTransferPairId} IS NULL OR ${FinanceSchema.transactionTransferPairId} != ${FinanceSchema.transactionId}),
        ${FinanceSchema.transactionCategoryId}      TEXT,
        ${FinanceSchema.transactionPayee}           TEXT,
        ${FinanceSchema.transactionType}            TEXT    NOT NULL CHECK (${FinanceSchema.transactionType} IN ('expense', 'income', 'transfer')),
        ${FinanceSchema.transactionAmountMinor}     INTEGER NOT NULL CHECK (${FinanceSchema.transactionAmountMinor} > 0),
        ${FinanceSchema.transactionCurrency}        TEXT    NOT NULL CHECK (length(${FinanceSchema.transactionCurrency}) = 3 AND ${FinanceSchema.transactionCurrency} GLOB '[A-Z][A-Z][A-Z]'),
        ${FinanceSchema.transactionDate}            TEXT    NOT NULL,
        ${FinanceSchema.transactionNote}            TEXT,
        ${FinanceSchema.transactionAttachmentIds}   TEXT,
        ${FinanceSchema.transactionCreatedAt}       TEXT    NOT NULL,
        ${FinanceSchema.transactionUpdatedAt}       TEXT    NOT NULL,
        ${FinanceSchema.transactionDeletedAt}       TEXT
      )
    ''');

    // Serves ITransactionRepository.findByAccount(accountId, {dateRange}).
    await ctx.execute('''
      CREATE INDEX idx_transactions_account_date
      ON ${FinanceSchema.transactionsTable} (${FinanceSchema.transactionAccountId}, ${FinanceSchema.transactionDate})
      WHERE ${FinanceSchema.transactionDeletedAt} IS NULL
    ''');

    // Serves ITransactionRepository.findByPeriod(period, {workspaceId}).
    await ctx.execute('''
      CREATE INDEX idx_transactions_workspace_date
      ON ${FinanceSchema.transactionsTable} (${FinanceSchema.transactionWorkspaceId}, ${FinanceSchema.transactionDate})
      WHERE ${FinanceSchema.transactionDeletedAt} IS NULL
    ''');

    // Serves ITransactionRepository.findByCategory(categoryId, {period}).
    await ctx.execute('''
      CREATE INDEX idx_transactions_category_date
      ON ${FinanceSchema.transactionsTable} (${FinanceSchema.transactionCategoryId}, ${FinanceSchema.transactionDate})
      WHERE ${FinanceSchema.transactionDeletedAt} IS NULL AND ${FinanceSchema.transactionCategoryId} IS NOT NULL
    ''');

    // Serves ITransactionRepository.saveTransferPair — pair lookups by leg id.
    await ctx.execute('''
      CREATE INDEX idx_transactions_transfer_pair_id
      ON ${FinanceSchema.transactionsTable} (${FinanceSchema.transactionTransferPairId})
      WHERE ${FinanceSchema.transactionTransferPairId} IS NOT NULL
    ''');

    // General workspace scoping for ITransactionRepository.query(TransactionQuery)
    // filter combinations not covered by the composite indexes above.
    await ctx.execute('''
      CREATE INDEX idx_transactions_workspace_id
      ON ${FinanceSchema.transactionsTable} (${FinanceSchema.transactionWorkspaceId})
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_transactions_workspace_id');
    await ctx.execute('DROP INDEX IF EXISTS idx_transactions_transfer_pair_id');
    await ctx.execute('DROP INDEX IF EXISTS idx_transactions_category_date');
    await ctx.execute('DROP INDEX IF EXISTS idx_transactions_workspace_date');
    await ctx.execute('DROP INDEX IF EXISTS idx_transactions_account_date');
    await ctx.execute('DROP TABLE IF EXISTS ${FinanceSchema.transactionsTable}');
  }
}
