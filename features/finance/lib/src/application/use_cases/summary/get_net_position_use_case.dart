import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:platform_core/platform_core.dart';

final class GetNetPositionInput {
  const GetNetPositionInput({
    required this.workspaceId,
    required this.period,
    required this.currency,
  });

  final String workspaceId;
  final FinancePeriod period;

  /// Reporting currency used for the result [Money].
  final CurrencyCode currency;
}

/// Returns net position (income − expenses) across all accounts for a period.
///
/// Net position = total income − total expenses. A positive value means the
/// workspace earned more than it spent; negative means overspend.
/// Transfer legs cancel out in aggregate (one expense + one income of equal
/// amounts) and do not affect net position.
final class GetNetPositionUseCase
    implements AsyncUseCase<GetNetPositionInput, Money> {
  const GetNetPositionUseCase({
    required IAccountRepository accountRepository,
    required ITransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository;

  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;

  @override
  Future<Result<Money>> execute(GetNetPositionInput input) async {
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

      var income = Decimal.zero;
      var expenses = Decimal.zero;

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
          switch (txn.type) {
            case TransactionType.income:
              income = income + txn.amount.amount;
            case TransactionType.expense:
              expenses = expenses + txn.amount.amount;
            case TransactionType.transfer:
              // Transfer legs are typed as expense/income — never reaches here
              break;
          }
        }
      }

      return Result.success(
          Money(amount: income - expenses, currency: input.currency));
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
