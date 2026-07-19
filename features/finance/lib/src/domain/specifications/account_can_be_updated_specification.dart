import 'package:application/application.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';

/// Specification for Account update eligibility.
///
/// Validates that the account exists in the repository and, when a new name
/// is supplied, that the name satisfies the DOC-031 §4.9 validation rules
/// (1–100 non-whitespace characters).
///
/// Currency immutability (DOC-031 Business Invariant 1) is enforced at the
/// use-case layer by excluding currency from [UpdateAccountInput]; this
/// specification does not re-validate it.
final class AccountCanBeUpdatedSpecification {
  const AccountCanBeUpdatedSpecification({
    required IAccountRepository accountRepository,
  }) : _accountRepository = accountRepository;

  final IAccountRepository _accountRepository;

  /// Returns [ValidationResult.valid] when the account exists and all supplied
  /// field values satisfy domain rules. All failures are accumulated — the
  /// result is not short-circuited on the first failure.
  ///
  /// [name] is optional; when `null` the existing name is kept and no name
  /// validation is performed.
  Future<ValidationResult> check(
    AccountId accountId, {
    required String workspaceId,
    String? name,
  }) async {
    final result = name != null ? _validateName(name) : const ValidationResult.valid();

    final accountResult = await _accountRepository.findById(
      accountId,
      workspaceId: workspaceId,
    );
    if (accountResult.isFailure) {
      return result.merge(ValidationResult.invalid([
        ValidationFailure(
          message:
              'Could not verify account: ${accountResult.exceptionOrNull!.message}',
          field: 'accountId',
        ),
      ]));
    }
    if (accountResult.valueOrNull == null) {
      return result.merge(ValidationResult.invalid([
        const ValidationFailure(
          message: 'Account does not exist.',
          field: 'accountId',
        ),
      ]));
    }

    return result;
  }

  ValidationResult _validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return ValidationResult.invalid([
        const ValidationFailure(
          message: 'Account name must not be empty.',
          field: 'name',
        ),
      ]);
    }
    if (trimmed.length > 100) {
      return ValidationResult.invalid([
        const ValidationFailure(
          message: 'Account name must not exceed 100 characters.',
          field: 'name',
        ),
      ]);
    }
    return const ValidationResult.valid();
  }
}
