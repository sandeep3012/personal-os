import 'package:application/application.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetTransactionsByAccountInput {
  const GetTransactionsByAccountInput({
    required this.accountId,
    required this.workspaceId,
    this.dateRange,
  });

  final AccountId accountId;
  final String workspaceId;
  final DateRange? dateRange;
}

/// Returns all non-deleted transactions for a given account.
///
/// Optionally restricted to a [DateRange]. Results are ordered by date
/// descending (enforced by the repository contract).
final class GetTransactionsByAccountUseCase
    implements
        AsyncUseCase<GetTransactionsByAccountInput, List<Transaction>> {
  const GetTransactionsByAccountUseCase({
    required ITransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  final ITransactionRepository _transactionRepository;

  @override
  Future<Result<List<Transaction>>> execute(
      GetTransactionsByAccountInput input) async {
    try {
      final result = await _transactionRepository.findByAccount(
        input.accountId,
        workspaceId: input.workspaceId,
        dateRange: input.dateRange,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return Result.success(result.valueOrNull!);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
