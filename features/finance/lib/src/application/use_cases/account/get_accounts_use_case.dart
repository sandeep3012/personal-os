import 'package:application/application.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetAccountsInput {
  const GetAccountsInput({
    required this.workspaceId,
    this.includeInactive = false,
  });

  final String workspaceId;

  /// When `true`, inactive accounts are included alongside active ones.
  ///
  /// Defaults to `false` so every existing caller (transaction/transfer
  /// account pickers, dashboard summaries) keeps seeing only active accounts
  /// exactly as before — an inactive account still cannot receive new
  /// transactions ([TransactionCanBeCreatedSpecification] enforces that
  /// separately. [AccountsViewModel] passes `true` so its own list screen
  /// can show (and let the user reactivate) an account it just deactivated,
  /// rather than the account silently vanishing with no way back.
  final bool includeInactive;
}

/// Returns accounts in the workspace — active-only by default, or every
/// non-deleted account when [GetAccountsInput.includeInactive] is `true`.
///
/// Soft-deleted accounts are never returned by the repository and require no
/// additional filter here.
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

      final accounts = input.includeInactive
          ? result.valueOrNull!
          : result.valueOrNull!.where((a) => a.isActive).toList();
      return Result.success(accounts);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
