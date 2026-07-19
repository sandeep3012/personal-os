import 'package:application/application.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:platform_core/platform_core.dart';

final class GetAccountBalanceInput {
  const GetAccountBalanceInput({
    required this.accountId,
    required this.workspaceId,
  });

  final AccountId accountId;
  final String workspaceId;
}

/// Computes the current balance of an Account.
///
/// Retrieves the Account's [initialBalance] and all its non-deleted
/// Transactions, then delegates arithmetic to [BalanceCalculationService].
final class GetAccountBalanceUseCase
    implements AsyncUseCase<GetAccountBalanceInput, Money> {
  const GetAccountBalanceUseCase({
    required IAccountRepository accountRepository,
    required ITransactionRepository transactionRepository,
    required BalanceCalculationService balanceCalculationService,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository,
        _balanceService = balanceCalculationService;

  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;
  final BalanceCalculationService _balanceService;

  @override
  Future<Result<Money>> execute(GetAccountBalanceInput input) async {
    try {
      final accountResult = await _accountRepository.findById(
        input.accountId,
        workspaceId: input.workspaceId,
      );
      if (accountResult.isFailure) {
        return Result.failure(accountResult.exceptionOrNull!);
      }

      final account = accountResult.valueOrNull;
      if (account == null) {
        return Result.failure(FinanceException(
          message: 'Account not found: ${input.accountId}',
        ));
      }

      final txnResult = await _transactionRepository.findByAccount(
        input.accountId,
        workspaceId: input.workspaceId,
      );
      if (txnResult.isFailure) return Result.failure(txnResult.exceptionOrNull!);

      final balance = _balanceService.calculateBalance(
        account.initialBalance,
        txnResult.valueOrNull!,
      );

      return Result.success(balance);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
