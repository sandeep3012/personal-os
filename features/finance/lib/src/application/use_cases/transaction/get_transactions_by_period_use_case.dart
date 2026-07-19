import 'package:application/application.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:platform_core/platform_core.dart';

final class GetTransactionsByPeriodInput {
  const GetTransactionsByPeriodInput({
    required this.workspaceId,
    required this.period,
  });

  final String workspaceId;
  final FinancePeriod period;
}

/// Returns all transactions across all accounts for a calendar month.
///
/// Converts [FinancePeriod] to a [DateRange], retrieves every account in the
/// workspace, then aggregates per-account transactions. No `findByPeriod`
/// method is required on the repository — this is adequate for Sprint 8A.
final class GetTransactionsByPeriodUseCase
    implements
        AsyncUseCase<GetTransactionsByPeriodInput, List<Transaction>> {
  const GetTransactionsByPeriodUseCase({
    required IAccountRepository accountRepository,
    required ITransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository;

  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;

  @override
  Future<Result<List<Transaction>>> execute(
      GetTransactionsByPeriodInput input) async {
    try {
      final period = input.period;
      final dateRange = DateRange(
        start: DateTime(period.year, period.month),
        // DateTime(y, m+1, 0) is the last moment of month m (handles December)
        end: DateTime(period.year, period.month + 1, 0),
      );

      final accountsResult =
          await _accountRepository.findAll(workspaceId: input.workspaceId);
      if (accountsResult.isFailure) {
        return Result.failure(accountsResult.exceptionOrNull!);
      }

      final all = <Transaction>[];
      for (final account in accountsResult.valueOrNull!) {
        final txnResult = await _transactionRepository.findByAccount(
          account.id,
          workspaceId: input.workspaceId,
          dateRange: dateRange,
        );
        if (txnResult.isFailure) {
          return Result.failure(txnResult.exceptionOrNull!);
        }
        all.addAll(txnResult.valueOrNull!);
      }

      return Result.success(all);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
