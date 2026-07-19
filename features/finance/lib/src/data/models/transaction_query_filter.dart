/// Persistence-layer filter parameters for [TransactionDao.query].
///
/// This is deliberately distinct from the domain `TransactionQuery` value
/// object — the DAO layer must not accept or return domain types. Field
/// values here are raw primitives (`String`, `DateTime`) rather than typed
/// domain identifiers (`AccountId`, `CategoryId`) or VOs (`DateRange`).
/// Translating between the two is a repository-layer concern.
final class TransactionQueryFilter {
  const TransactionQueryFilter({
    required this.workspaceId,
    this.accountId,
    this.categoryId,
    this.transactionType,
    this.startDate,
    this.endDate,
    this.payeeContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final String? accountId;
  final String? categoryId;
  final String? transactionType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? payeeContains;
  final int pageIndex;
  final int pageSize;
}
