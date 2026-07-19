import 'package:application/application.dart';
import 'package:feature_finance/src/application/support/validation_result_x.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_deleted_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteAccountInput {
  const DeleteAccountInput({
    required this.accountId,
    required this.workspaceId,
  });

  final AccountId accountId;
  final String workspaceId;
}

/// Removes an Account from the workspace.
///
/// Enforces DOC-031 Business Invariant 5 via [AccountCanBeDeletedSpecification]:
/// an Account that still owns active Transactions cannot be deleted. The
/// caller must first remove or reassign all transactions before deletion is
/// permitted.
final class DeleteAccountUseCase
    implements AsyncUseCase<DeleteAccountInput, void> {
  const DeleteAccountUseCase({
    required IAccountRepository accountRepository,
    required AccountCanBeDeletedSpecification specification,
  })  : _accountRepository = accountRepository,
        _specification = specification;

  final IAccountRepository _accountRepository;
  final AccountCanBeDeletedSpecification _specification;

  @override
  Future<Result<void>> execute(DeleteAccountInput input) async {
    try {
      final validation = await _specification.check(
        input.accountId,
        workspaceId: input.workspaceId,
      );
      if (validation.isInvalid) {
        return Result.failure(validation.toFinanceException());
      }

      final deleteResult = await _accountRepository.softDelete(
        input.accountId,
        workspaceId: input.workspaceId,
      );
      if (deleteResult.isFailure) {
        return Result.failure(deleteResult.exceptionOrNull!);
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
