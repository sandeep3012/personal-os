/// Table and column name constants for the Finance SQLite schema.
///
/// Single source of truth for identifiers referenced by both the schema
/// migrations (`lib/src/data/migrations/`) and the future repository
/// implementations (Sprint 8B Step 2). Keeping names here — rather than as
/// string literals scattered across migration and repository files — ensures
/// a rename only ever needs to happen in one place.
abstract final class FinanceSchema {
  // ── Accounts table ────────────────────────────────────────────────────────

  static const accountsTable = 'accounts';

  static const accountId = 'account_id';
  static const accountWorkspaceId = 'workspace_id';
  static const accountName = 'name';
  static const accountType = 'account_type';
  static const accountCurrency = 'currency';
  static const accountOpeningBalanceMinor = 'opening_balance_minor';
  static const accountIsActive = 'is_active';
  static const accountCreatedAt = 'created_at';
  static const accountUpdatedAt = 'updated_at';
  static const accountDeletedAt = 'deleted_at';

  // ── Transactions table ────────────────────────────────────────────────────

  static const transactionsTable = 'transactions';

  static const transactionId = 'transaction_id';
  static const transactionWorkspaceId = 'workspace_id';
  static const transactionAccountId = 'account_id';
  static const transactionTransferPairId = 'transfer_pair_id';
  static const transactionCategoryId = 'category_id';
  static const transactionPayee = 'payee';
  static const transactionType = 'transaction_type';
  static const transactionAmountMinor = 'amount_minor';
  static const transactionCurrency = 'currency';
  static const transactionDate = 'transaction_date';
  static const transactionNote = 'note';
  static const transactionAttachmentIds = 'attachment_ids';
  static const transactionCreatedAt = 'created_at';
  static const transactionUpdatedAt = 'updated_at';
  static const transactionDeletedAt = 'deleted_at';

  // ── Column ordering (DAO insert/update column lists) ─────────────────────
  //
  // Single source of truth for positional column order so DAOs never
  // hand-write a column list twice (once for INSERT, once for the row map).

  static const List<String> accountColumns = [
    accountId,
    accountWorkspaceId,
    accountName,
    accountType,
    accountCurrency,
    accountOpeningBalanceMinor,
    accountIsActive,
    accountCreatedAt,
    accountUpdatedAt,
    accountDeletedAt,
  ];

  static const List<String> transactionColumns = [
    transactionId,
    transactionWorkspaceId,
    transactionAccountId,
    transactionTransferPairId,
    transactionCategoryId,
    transactionPayee,
    transactionType,
    transactionAmountMinor,
    transactionCurrency,
    transactionDate,
    transactionNote,
    transactionAttachmentIds,
    transactionCreatedAt,
    transactionUpdatedAt,
    transactionDeletedAt,
  ];
}
