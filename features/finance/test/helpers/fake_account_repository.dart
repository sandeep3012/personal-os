import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [IAccountRepository] for use-case unit tests.
final class FakeAccountRepository implements IAccountRepository {
  final List<Account> _store = [];

  List<Account> get store => List.unmodifiable(_store);

  void seed(List<Account> accounts) {
    _store.clear();
    _store.addAll(accounts);
  }

  @override
  FutureResult<Account?> findById(
    AccountId id, {
    required String workspaceId,
  }) async =>
      Result.success(_store.where((a) => a.id == id).firstOrNull);

  @override
  FutureResult<List<Account>> findAll({required String workspaceId}) async =>
      Result.success(List.unmodifiable(_store));

  @override
  FutureResult<List<Account>> findActive({required String workspaceId}) async =>
      Result.success(
        List.unmodifiable(_store.where((a) => a.isActive).toList()),
      );

  @override
  FutureResult<void> save(Account account) async {
    _store.removeWhere((a) => a.id == account.id);
    _store.add(account);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(
    AccountId id, {
    required String workspaceId,
  }) async {
    _store.removeWhere((a) => a.id == id);
    return const Result.success(null);
  }
}
