import 'package:application/application.dart';
import 'package:feature_finance/src/application/support/validation_result_x.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_updated_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateAccountInput {
  const UpdateAccountInput({
    required this.accountId,
    required this.workspaceId,
    this.name,
    this.isActive,
  });

  final AccountId accountId;
  final String workspaceId;

  /// New display name. `null` keeps the existing name.
  final String? name;

  /// Updated active flag. `null` keeps the existing value.
  final bool? isActive;
}

/// Updates the mutable fields of an existing Account.
///
/// Currency is intentionally absent from [UpdateAccountInput] — it is
/// immutable after creation (DOC-031 Business Invariant 1). Existence and
/// name validity are enforced by [AccountCanBeUpdatedSpecification].
final class UpdateAccountUseCase
    implements AsyncUseCase<UpdateAccountInput, Account> {
  const UpdateAccountUseCase({
    required IAccountRepository accountRepository,
    required AccountCanBeUpdatedSpecification specification,
  })  : _accountRepository = accountRepository,
        _specification = specification;

  final IAccountRepository _accountRepository;
  final AccountCanBeUpdatedSpecification _specification;

  @override
  Future<Result<Account>> execute(UpdateAccountInput input) async {
    try {
      final validation = await _specification.check(
        input.accountId,
        workspaceId: input.workspaceId,
        name: input.name,
      );
      if (validation.isInvalid) {
        return Result.failure(validation.toFinanceException());
      }

      final findResult = await _accountRepository.findById(
        input.accountId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) return Result.failure(findResult.exceptionOrNull!);

      // The specification already confirmed the account exists.
      final existing = findResult.valueOrNull!;

      final updated = existing.copyWith(
        name: input.name ?? existing.name,
        isActive: input.isActive ?? existing.isActive,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _accountRepository.save(updated);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
