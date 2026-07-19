import 'package:feature_finance/src/data/dao/account_dao.dart';
import 'package:feature_finance/src/data/mappers/account_mapper.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [IAccountRepository].
///
/// Pure orchestration: delegates all SQL to [AccountDao] and all
/// entity/row conversion to [AccountMapper]. Never builds SQL, never
/// performs Money conversion, never applies business rules — those
/// responsibilities belong to the DAO, the mapper, and the domain/
/// specification layers respectively. [AccountRow] never escapes this
/// class — every public method returns a domain [Account] (or nothing).
final class AccountRepository implements IAccountRepository {
  const AccountRepository({
    required AccountDao accountDao,
    required AccountMapper accountMapper,
  })  : _accountDao = accountDao,
        _accountMapper = accountMapper;

  final AccountDao _accountDao;
  final AccountMapper _accountMapper;

  @override
  FutureResult<Account?> findById(
    AccountId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _accountDao.findById(id.value, workspaceId: workspaceId);
      if (row == null) return const Result.success(null);
      return Result.success(_accountMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Account>> findAll({required String workspaceId}) async {
    try {
      final rows = await _accountDao.findAll(workspaceId);
      return Result.success(rows.map(_accountMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Account>> findActive({required String workspaceId}) async {
    try {
      final rows = await _accountDao.findActive(workspaceId);
      return Result.success(rows.map(_accountMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Account account) async {
    try {
      final row = _accountMapper.toRow(account);
      final alreadyExists = await _accountDao.exists(
        account.id.value,
        workspaceId: account.workspaceId,
      );
      if (alreadyExists) {
        await _accountDao.update(row);
      } else {
        await _accountDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    AccountId id, {
    required String workspaceId,
  }) async {
    try {
      await _accountDao.softDelete(
        id.value,
        workspaceId: workspaceId,
        deletedAt: DateTime.now(),
      );
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  /// Translates any failure raised by the DAO or mapper into a
  /// [FinanceException] so callers never see a raw database or
  /// persistence-layer exception. Exceptions already typed as [AppException]
  /// (e.g. a mapper's data-corruption error) are passed through unchanged
  /// rather than being double-wrapped.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return FinanceException(
      message: 'Account repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
