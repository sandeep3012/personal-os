import 'package:application/application.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';

/// Specification for Business Invariant 5 (DOC-031 §4.8):
/// An Account can only be deleted when it exists and has no active Transactions.
///
/// This specification makes the invariant explicit and testable without
/// duplicating it across use cases.
final class AccountCanBeDeletedSpecification {
  const AccountCanBeDeletedSpecification({
    required IAccountRepository accountRepository,
    required ITransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository;

  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;

  /// Returns [ValidationResult.valid] when the account exists and owns no
  /// active transactions. Returns [ValidationResult.invalid] with one failure
  /// per violated condition.
  Future<ValidationResult> check(
    AccountId accountId, {
    required String workspaceId,
  }) async {
    final accountResult = await _accountRepository.findById(
      accountId,
      workspaceId: workspaceId,
    );
    if (accountResult.isFailure) {
      return ValidationResult.invalid([
        ValidationFailure(
          message:
              'Could not verify account: ${accountResult.exceptionOrNull!.message}',
          field: 'accountId',
        ),
      ]);
    }
    if (accountResult.valueOrNull == null) {
      return ValidationResult.invalid([
        const ValidationFailure(
          message: 'Account does not exist.',
          field: 'accountId',
        ),
      ]);
    }

    final txnResult = await _transactionRepository.findActiveByAccount(
      accountId,
      workspaceId: workspaceId,
    );
    if (txnResult.isFailure) {
      return ValidationResult.invalid([
        ValidationFailure(
          message:
              'Could not verify transactions: ${txnResult.exceptionOrNull!.message}',
        ),
      ]);
    }
    if (txnResult.valueOrNull!.isNotEmpty) {
      return ValidationResult.invalid([
        const ValidationFailure(
          message:
              'Account has active transactions and cannot be deleted. '
              'Remove or reassign all transactions first.',
        ),
      ]);
    }

    return const ValidationResult.valid();
  }
}
