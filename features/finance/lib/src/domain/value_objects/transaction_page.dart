import 'package:feature_finance/src/domain/entities/transaction.dart';

/// A single page of [Transaction] results from [QueryTransactionsUseCase].
final class TransactionPage {
  const TransactionPage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<Transaction> items;
  final int totalCount;
  final bool hasNextPage;
}
