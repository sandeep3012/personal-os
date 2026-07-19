import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:platform_core/platform_core.dart';

/// Filter and pagination parameters for [QueryTransactionsUseCase].
///
/// All filter fields are optional — absent fields impose no constraint.
/// Results are paginated via [pageIndex] / [pageSize].
final class TransactionQuery {
  const TransactionQuery({
    required this.workspaceId,
    this.accountId,
    this.categoryId,
    this.type,
    this.dateRange,
    this.payeeNameContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final AccountId? accountId;
  final CategoryId? categoryId;
  final TransactionType? type;
  final DateRange? dateRange;
  final String? payeeNameContains;
  final int pageIndex;
  final int pageSize;
}
