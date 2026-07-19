import 'package:application/application.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';

/// Specification for Transfer creation eligibility (DOC-031 §4.8 BI-3, BI-4).
///
/// Validates:
/// - Source and destination accounts differ (Business Invariant 4).
/// - Both accounts exist.
/// - Both accounts are active.
/// - Both accounts share the same currency (cross-currency transfers are
///   deferred to a future sprint per DOC-031 §3.2).
///
/// All failures are accumulated — the result is not short-circuited.
final class TransferCanBeCreatedSpecification {
  const TransferCanBeCreatedSpecification({
    required IAccountRepository accountRepository,
  }) : _accountRepository = accountRepository;

  final IAccountRepository _accountRepository;

  /// Returns [ValidationResult.valid] when the transfer is permitted.
  Future<ValidationResult> check({
    required AccountId fromAccountId,
    required AccountId toAccountId,
    required String workspaceId,
  }) async {
    // Business Invariant 4: accounts must differ.
    if (fromAccountId == toAccountId) {
      return ValidationResult.invalid([
        const ValidationFailure(
          message: 'Source and destination accounts must be different.',
          field: 'toAccountId',
        ),
      ]);
    }

    var result = const ValidationResult.valid();

    // Fetch both accounts in parallel.
    final fromFuture = _accountRepository.findById(
      fromAccountId,
      workspaceId: workspaceId,
    );
    final toFuture = _accountRepository.findById(
      toAccountId,
      workspaceId: workspaceId,
    );

    final fromResult = await fromFuture;
    final toResult = await toFuture;

    // Validate source account.
    if (fromResult.isFailure) {
      result = result.merge(ValidationResult.invalid([
        ValidationFailure(
          message:
              'Could not verify source account: ${fromResult.exceptionOrNull!.message}',
          field: 'fromAccountId',
        ),
      ]));
    } else if (fromResult.valueOrNull == null) {
      result = result.merge(ValidationResult.invalid([
        const ValidationFailure(
          message: 'Source account does not exist.',
          field: 'fromAccountId',
        ),
      ]));
    } else if (!fromResult.valueOrNull!.isActive) {
      result = result.merge(ValidationResult.invalid([
        const ValidationFailure(
          message: 'Source account is inactive.',
          field: 'fromAccountId',
        ),
      ]));
    }

    // Validate destination account.
    if (toResult.isFailure) {
      result = result.merge(ValidationResult.invalid([
        ValidationFailure(
          message:
              'Could not verify destination account: ${toResult.exceptionOrNull!.message}',
          field: 'toAccountId',
        ),
      ]));
    } else if (toResult.valueOrNull == null) {
      result = result.merge(ValidationResult.invalid([
        const ValidationFailure(
          message: 'Destination account does not exist.',
          field: 'toAccountId',
        ),
      ]));
    } else if (!toResult.valueOrNull!.isActive) {
      result = result.merge(ValidationResult.invalid([
        const ValidationFailure(
          message: 'Destination account is inactive.',
          field: 'toAccountId',
        ),
      ]));
    }

    // Currency check — only meaningful when both accounts resolved successfully.
    final fromAccount = fromResult.isSuccess ? fromResult.valueOrNull : null;
    final toAccount = toResult.isSuccess ? toResult.valueOrNull : null;
    if (fromAccount != null && toAccount != null &&
        fromAccount.currency != toAccount.currency) {
      result = result.merge(ValidationResult.invalid([
        ValidationFailure(
          message:
              'Source account currency (${fromAccount.currency.value}) does not '
              'match destination account currency (${toAccount.currency.value}). '
              'Cross-currency transfers are not supported in this version.',
          field: 'currency',
        ),
      ]));
    }

    return result;
  }
}
