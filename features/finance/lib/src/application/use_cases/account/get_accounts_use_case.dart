import 'package:application/application.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetAccountsInput {
  const GetAccountsInput({required this.workspaceId});

  final String workspaceId;
}

/// Returns all active (non-disabled) accounts in the workspace.
///
/// Inactive accounts (isActive == false) are excluded. Soft-deleted accounts
/// are never returned by the repository and require no additional filter here.
final class GetAccountsUseCase
    implements AsyncUseCase<GetAccountsInput, List<Account>> {
  const GetAccountsUseCase({required IAccountRepository accountRepository})
      : _accountRepository = accountRepository;

  final IAccountRepository _accountRepository;

  @override
  Future<Result<List<Account>>> execute(GetAccountsInput input) async {
    try {
      final result =
          await _accountRepository.findAll(workspaceId: input.workspaceId);
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final active =
          result.valueOrNull!.where((a) => a.isActive).toList();
      return Result.success(active);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
