import 'package:application/application.dart';
import 'package:feature_finance/src/application/support/validation_result_x.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/specifications/transfer_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:platform_core/platform_core.dart';

final class CreateTransferInput {
  const CreateTransferInput({
    required this.workspaceId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String workspaceId;
  final AccountId fromAccountId;
  final AccountId toAccountId;
  final Money amount;
  final TransactionDate date;
  final String? note;
}

final class CreateTransferOutput {
  const CreateTransferOutput({required this.debit, required this.credit});

  final Transaction debit;
  final Transaction credit;
}

/// Creates a transfer between two accounts in the same workspace.
///
/// Account existence, active status, and currency match are enforced by
/// [TransferCanBeCreatedSpecification]. Pair creation is delegated to
/// [TransferService] (which re-asserts Business Invariant 4 as
/// defense-in-depth), and both legs are persisted atomically via
/// [ITransactionRepository.saveTransferPair].
final class CreateTransferUseCase
    implements AsyncUseCase<CreateTransferInput, CreateTransferOutput> {
  CreateTransferUseCase({
    required ITransactionRepository transactionRepository,
    required TransferService transferService,
    required TransferCanBeCreatedSpecification specification,
  })  : _transactionRepository = transactionRepository,
        _transferService = transferService,
        _specification = specification;

  final ITransactionRepository _transactionRepository;
  final TransferService _transferService;
  final TransferCanBeCreatedSpecification _specification;

  @override
  Future<Result<CreateTransferOutput>> execute(
      CreateTransferInput input) async {
    try {
      final validation = await _specification.check(
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        workspaceId: input.workspaceId,
      );
      if (validation.isInvalid) {
        return Result.failure(validation.toFinanceException());
      }

      final (debit, credit) = _transferService.createTransferPair(
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        workspaceId: input.workspaceId,
        amount: input.amount,
        date: input.date,
        note: input.note,
      );

      final saveResult =
          await _transactionRepository.saveTransferPair(debit, credit);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(
          CreateTransferOutput(debit: debit, credit: credit));
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
