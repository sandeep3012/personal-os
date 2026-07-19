import 'package:application/application.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';

/// Specification for Transaction creation eligibility.
///
/// Validates that the target account exists, is active, and that the
/// requested transaction currency matches the account's currency
/// (DOC-031 §4.9 — currency must match account currency).
///
/// Amount positivity and date validity are enforced by [Money] and
/// [TransactionDate] VO constructors respectively; this specification
/// does not duplicate that enforcement.
final class TransactionCanBeCreatedSpecification {
  const TransactionCanBeCreatedSpecification({
    required IAccountRepository accountRepository,
  }) : _accountRepository = accountRepository;

  final IAccountRepository _accountRepository;

  /// Returns [ValidationResult.valid] when the account accepts the transaction.
  /// All failures are accumulated — the result is not short-circuited.
  ///
  /// [currency] is the currency of the transaction being created; it must
  /// match the account's own currency.
  Future<ValidationResult> check(
    AccountId accountId, {
    required String workspaceId,
    required CurrencyCode currency,
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

    final account = accountResult.valueOrNull;
    if (account == null) {
      return ValidationResult.invalid([
        const ValidationFailure(
          message: 'Account does not exist.',
          field: 'accountId',
        ),
      ]);
    }

    var result = const ValidationResult.valid();

    if (!account.isActive) {
      result = result.merge(ValidationResult.invalid([
        const ValidationFailure(
          message:
              'Account is inactive. Transactions cannot be added to an inactive account.',
          field: 'accountId',
        ),
      ]));
    }

    if (account.currency != currency) {
      result = result.merge(ValidationResult.invalid([
        ValidationFailure(
          message:
              'Transaction currency (${currency.value}) does not match '
              'account currency (${account.currency.value}).',
          field: 'currency',
        ),
      ]));
    }

    return result;
  }
}
