import 'package:application/application.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/services/category_summary_service.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:platform_core/platform_core.dart';

final class GetCategorySummaryInput {
  const GetCategorySummaryInput({
    required this.workspaceId,
    required this.period,
  });

  final String workspaceId;
  final FinancePeriod period;
}

/// Returns expense totals grouped by category for a calendar month.
///
/// Delegates aggregation to [CategorySummaryService]. Returns an empty map
/// when there are no categorised expense transactions in the period.
final class GetCategorySummaryUseCase
    implements
        AsyncUseCase<GetCategorySummaryInput, Map<CategoryId, Money>> {
  const GetCategorySummaryUseCase({
    required IAccountRepository accountRepository,
    required ITransactionRepository transactionRepository,
    required CategorySummaryService categorySummaryService,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository,
        _categorySummaryService = categorySummaryService;

  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;
  final CategorySummaryService _categorySummaryService;

  @override
  Future<Result<Map<CategoryId, Money>>> execute(
      GetCategorySummaryInput input) async {
    try {
      final period = input.period;
      final dateRange = DateRange(
        start: DateTime(period.year, period.month),
        end: DateTime(period.year, period.month + 1, 0),
      );

      final accountsResult =
          await _accountRepository.findAll(workspaceId: input.workspaceId);
      if (accountsResult.isFailure) {
        return Result.failure(accountsResult.exceptionOrNull!);
      }

      final allTransactions = <Transaction>[];
      for (final account in accountsResult.valueOrNull!) {
        final txnResult = await _transactionRepository.findByAccount(
          account.id,
          workspaceId: input.workspaceId,
          dateRange: dateRange,
        );
        if (txnResult.isFailure) {
          return Result.failure(txnResult.exceptionOrNull!);
        }
        allTransactions.addAll(txnResult.valueOrNull!);
      }

      final summary =
          _categorySummaryService.summarizeByCategory(allTransactions);

      return Result.success(summary);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
