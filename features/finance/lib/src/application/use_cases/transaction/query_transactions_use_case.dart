import 'package:application/application.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_page.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:platform_core/platform_core.dart';

/// Executes a [TransactionQuery] and returns a paginated [TransactionPage].
///
/// In-memory filtering is used for Sprint 8A domain testing. A specific
/// account is queried directly when [TransactionQuery.accountId] is set;
/// otherwise all workspace accounts are queried and results are merged.
final class QueryTransactionsUseCase
    implements AsyncUseCase<TransactionQuery, TransactionPage> {
  const QueryTransactionsUseCase({
    required IAccountRepository accountRepository,
    required ITransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository;

  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;

  @override
  Future<Result<TransactionPage>> execute(TransactionQuery input) async {
    try {
      // 1. Fetch raw transactions for the relevant account(s)
      final fetched = <Transaction>[];

      if (input.accountId != null) {
        final result = await _transactionRepository.findByAccount(
          input.accountId!,
          workspaceId: input.workspaceId,
          dateRange: input.dateRange,
        );
        if (result.isFailure) return Result.failure(result.exceptionOrNull!);
        fetched.addAll(result.valueOrNull!);
      } else {
        final accountsResult = await _accountRepository.findAll(
          workspaceId: input.workspaceId,
        );
        if (accountsResult.isFailure) {
          return Result.failure(accountsResult.exceptionOrNull!);
        }
        for (final account in accountsResult.valueOrNull!) {
          final result = await _transactionRepository.findByAccount(
            account.id,
            workspaceId: input.workspaceId,
            dateRange: input.dateRange,
          );
          if (result.isFailure) return Result.failure(result.exceptionOrNull!);
          fetched.addAll(result.valueOrNull!);
        }
      }

      // 2. In-memory filter
      final filtered = fetched.where((t) {
        if (input.type != null && t.type != input.type) return false;
        if (input.categoryId != null && t.categoryId != input.categoryId) {
          return false;
        }
        if (input.payeeNameContains != null &&
            input.payeeNameContains!.isNotEmpty) {
          final payeeValue = t.payee?.value;
          if (payeeValue == null) return false;
          if (!payeeValue
              .toLowerCase()
              .contains(input.payeeNameContains!.toLowerCase())) {
            return false;
          }
        }
        return true;
      }).toList();

      // 3. Paginate
      final total = filtered.length;
      final start = input.pageIndex * input.pageSize;
      final end = (start + input.pageSize).clamp(0, total);
      final items = start >= total ? <Transaction>[] : filtered.sublist(start, end);
      final hasNext = end < total;

      return Result.success(TransactionPage(
        items: List.unmodifiable(items),
        totalCount: total,
        hasNextPage: hasNext,
      ));
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
