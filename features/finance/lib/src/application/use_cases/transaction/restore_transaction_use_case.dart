import 'package:application/application.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:platform_core/platform_core.dart';

final class RestoreTransactionInput {
  const RestoreTransactionInput({
    required this.transactionId,
    required this.workspaceId,
  });

  final TransactionId transactionId;
  final String workspaceId;
}

/// Reverses a soft-delete for a single Transaction — the Undo half of
/// [DeleteTransactionUseCase], which it deliberately mirrors field-for-field.
///
/// Internal to the Finance feature. This exists solely to back the swipe-to-
/// delete Undo affordance on [TransactionsPage] — it is not exported from
/// `finance.dart` (mirroring how every other use case is DI-resolved only,
/// never imported directly by a consumer) and must not be generalized into
/// a reusable "undelete" capability for other entities or features. Only
/// ever restores a transaction that is currently soft-deleted —
/// [ITransactionRepository.restoreTransaction] is a no-op (still success)
/// for anything else.
final class RestoreTransactionUseCase
    implements AsyncUseCase<RestoreTransactionInput, void> {
  const RestoreTransactionUseCase({
    required ITransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  final ITransactionRepository _transactionRepository;

  @override
  Future<Result<void>> execute(RestoreTransactionInput input) async {
    try {
      final result = await _transactionRepository.restoreTransaction(
        input.transactionId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
