import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Account persistence, expressed in domain terms.
///
/// Implementations are internal to the Finance feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-delete is the only supported removal strategy — hard deletion is not
/// permitted in MVP (Business Invariant 5).
abstract interface class IAccountRepository {
  /// Returns the [Account] with [id] within [workspaceId], or `null` if no
  /// matching account exists.
  FutureResult<Account?> findById(
    AccountId id, {
    required String workspaceId,
  });

  /// Returns all non-deleted accounts within [workspaceId].
  ///
  /// Returns an empty list when no accounts have been created — never fails
  /// for an empty workspace.
  FutureResult<List<Account>> findAll({required String workspaceId});

  /// Returns all non-deleted, active accounts within [workspaceId].
  ///
  /// Active accounts have [Account.isActive] == `true`. Inactive (soft-disabled)
  /// accounts are excluded. Returns an empty list when none exist.
  FutureResult<List<Account>> findActive({required String workspaceId});

  /// Persists [account]. Creates it if it is new; updates it if it already
  /// exists.
  FutureResult<void> save(Account account);

  /// Marks the account identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the account has already been removed.
  /// Implementations must use a soft-delete strategy; hard deletion is not
  /// supported in MVP. Callers (specifically [DeleteAccountUseCase]) must
  /// verify that no active transactions exist before invoking this method.
  FutureResult<void> softDelete(AccountId id, {required String workspaceId});
}
