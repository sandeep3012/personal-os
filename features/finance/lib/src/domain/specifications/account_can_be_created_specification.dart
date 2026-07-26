import 'package:application/application.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';

/// Specification for Account creation eligibility.
///
/// Validates that [name] satisfies the DOC-031 §4.9 validation rules (1–100
/// non-whitespace characters) and is not already used by another active
/// account in the same workspace (case-insensitive) — closes the gap that
/// previously let [CreateAccountUseCase] create duplicate-named accounts
/// with no validation at all.
///
/// Mirrors [AccountCanBeUpdatedSpecification]'s name-validation rules
/// exactly; the uniqueness check is additional since a *new* account always
/// introduces a fresh identity into the workspace, unlike an update (which
/// may keep its own existing name unchanged).
final class AccountCanBeCreatedSpecification {
  const AccountCanBeCreatedSpecification({
    required IAccountRepository accountRepository,
  }) : _accountRepository = accountRepository;

  final IAccountRepository _accountRepository;

  /// Returns [ValidationResult.valid] when [name] is well-formed and not
  /// already used by another active account in [workspaceId]. All failures
  /// are accumulated — the result is not short-circuited on the first one.
  Future<ValidationResult> check(
    String name, {
    required String workspaceId,
  }) async {
    var result = _validateName(name);

    final activeResult = await _accountRepository.findActive(workspaceId: workspaceId);
    if (activeResult.isFailure) {
      return result.merge(ValidationResult.invalid([
        ValidationFailure(
          message:
              'Could not verify existing accounts: ${activeResult.exceptionOrNull!.message}',
        ),
      ]));
    }

    final trimmed = name.trim().toLowerCase();
    final isDuplicate = activeResult.valueOrNull!
        .any((account) => account.name.trim().toLowerCase() == trimmed);
    if (isDuplicate) {
      result = result.merge(ValidationResult.invalid([
        ValidationFailure(
          message: 'An account named "${name.trim()}" already exists.',
          field: 'name',
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
