import 'package:application/application.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetAccountByIdInput {
  const GetAccountByIdInput({
    required this.accountId,
    required this.workspaceId,
  });

  final AccountId accountId;
  final String workspaceId;
}

/// Returns a single Account by its identifier.
///
/// Fails with [FinanceException] when no account with [GetAccountByIdInput.accountId]
/// exists in the workspace.
final class GetAccountByIdUseCase
    implements AsyncUseCase<GetAccountByIdInput, Account> {
  const GetAccountByIdUseCase({required IAccountRepository accountRepository})
      : _accountRepository = accountRepository;

  final IAccountRepository _accountRepository;

  @override
  Future<Result<Account>> execute(GetAccountByIdInput input) async {
    try {
      final result = await _accountRepository.findById(
        input.accountId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final account = result.valueOrNull;
      if (account == null) {
        return Result.failure(FinanceException(
          message: 'Account not found: ${input.accountId}',
        ));
      }

      return Result.success(account);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
