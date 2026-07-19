import 'package:application/application.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateTransactionInput {
  const UpdateTransactionInput({
    required this.transactionId,
    required this.workspaceId,
    this.amount,
    this.date,
    this.payee,
    this.categoryId,
    this.note,
  });

  final TransactionId transactionId;
  final String workspaceId;

  // null = keep existing value
  final Money? amount;
  final TransactionDate? date;
  final Payee? payee;
  final CategoryId? categoryId;
  final String? note;
}

/// Updates mutable fields of an existing Transaction.
///
/// Transaction type and accountId are immutable after creation (structurally
/// enforced by omitting them from [UpdateTransactionInput]).
final class UpdateTransactionUseCase
    implements AsyncUseCase<UpdateTransactionInput, Transaction> {
  const UpdateTransactionUseCase({
    required ITransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  final ITransactionRepository _transactionRepository;

  @override
  Future<Result<Transaction>> execute(UpdateTransactionInput input) async {
    try {
      final findResult = await _transactionRepository.findById(
        input.transactionId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) return Result.failure(findResult.exceptionOrNull!);

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(FinanceException(
          message: 'Transaction not found: ${input.transactionId}',
        ));
      }

      final updated = Transaction(
        id: existing.id,
        workspaceId: existing.workspaceId,
        accountId: existing.accountId,
        type: existing.type,
        amount: input.amount ?? existing.amount,
        categoryId: input.categoryId ?? existing.categoryId,
        payee: input.payee ?? existing.payee,
        note: input.note ?? existing.note,
        date: input.date ?? existing.date,
        attachmentIds: existing.attachmentIds,
        transferCounterpartId: existing.transferCounterpartId,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _transactionRepository.save(updated);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
