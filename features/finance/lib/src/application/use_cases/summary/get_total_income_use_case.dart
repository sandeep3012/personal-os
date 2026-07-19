import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:platform_core/platform_core.dart';

final class GetTotalIncomeInput {
  const GetTotalIncomeInput({
    required this.workspaceId,
    required this.period,
    required this.currency,
  });

  final String workspaceId;
  final FinancePeriod period;

  /// Reporting currency; returned in the zero-value [Money] when there are
  /// no income transactions for the period.
  final CurrencyCode currency;
}

/// Returns the total income amount across all accounts for a calendar month.
///
/// Sums only [TransactionType.income] legs (transfer credit legs are income
/// and are included). Returns `Money(amount: Decimal.zero, currency: …)` when
/// there are no matching transactions.
final class GetTotalIncomeUseCase
    implements AsyncUseCase<GetTotalIncomeInput, Money> {
  const GetTotalIncomeUseCase({
    required IAccountRepository accountRepository,
    required ITransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository;

  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;

  @override
  Future<Result<Money>> execute(GetTotalIncomeInput input) async {
    try {
      final period = input.period;
      final dateRange = DateRange(
        start: DateTime(period.year, period.month),
        end: DateTime(period.year, period.month + 1, 0),
      );

      final accountsResult =
          await _accountRepository.findAll(workspaceId: input.workspaceId);
      if (accountsResult.isFailure) {
        return Result.failure(accountsResult.exceptionOrNull!);
      }

      var total = Decimal.zero;
      for (final account in accountsResult.valueOrNull!) {
        final txnResult = await _transactionRepository.findByAccount(
          account.id,
          workspaceId: input.workspaceId,
          dateRange: dateRange,
        );
        if (txnResult.isFailure) {
          return Result.failure(txnResult.exceptionOrNull!);
        }
        for (final txn in txnResult.valueOrNull!) {
          if (txn.type == TransactionType.income) {
            total = total + txn.amount.amount;
          }
        }
      }

      return Result.success(Money(amount: total, currency: input.currency));
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
