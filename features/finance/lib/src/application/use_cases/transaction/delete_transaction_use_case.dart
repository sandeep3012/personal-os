import 'package:application/application.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteTransactionInput {
  const DeleteTransactionInput({
    required this.transactionId,
    required this.workspaceId,
  });

  final TransactionId transactionId;
  final String workspaceId;
}

/// Removes a Transaction from the workspace.
///
/// Deletion is idempotent — succeeds even if the transaction no longer exists.
final class DeleteTransactionUseCase
    implements AsyncUseCase<DeleteTransactionInput, void> {
  const DeleteTransactionUseCase({
    required ITransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  final ITransactionRepository _transactionRepository;

  @override
  Future<Result<void>> execute(DeleteTransactionInput input) async {
    try {
      final result = await _transactionRepository.softDelete(
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
