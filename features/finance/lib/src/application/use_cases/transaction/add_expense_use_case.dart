import 'package:application/application.dart';
import 'package:feature_finance/src/application/support/validation_result_x.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/repositories/i_transaction_repository.dart';
import 'package:feature_finance/src/domain/specifications/transaction_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:platform_core/platform_core.dart';

final class AddExpenseInput {
  const AddExpenseInput({
    required this.workspaceId,
    required this.accountId,
    required this.amount,
    required this.date,
    this.payee,
    this.categoryId,
    this.note,
    this.attachmentIds = const [],
  });

  final String workspaceId;
  final AccountId accountId;
  final Money amount;
  final TransactionDate date;
  final Payee? payee;
  final CategoryId? categoryId;
  final String? note;
  final List<String> attachmentIds;
}

/// Records an expense Transaction and persists it.
///
/// Account existence, active status, and currency match are enforced by
/// [TransactionCanBeCreatedSpecification]. Amount validity (> 0) is enforced
/// by the [Transaction] entity constructor as defense-in-depth.
final class AddExpenseUseCase
    implements AsyncUseCase<AddExpenseInput, Transaction> {
  AddExpenseUseCase({
    required ITransactionRepository transactionRepository,
    required IdGenerator idGenerator,
    required TransactionCanBeCreatedSpecification specification,
  })  : _transactionRepository = transactionRepository,
        _idGenerator = idGenerator,
        _specification = specification;

  final ITransactionRepository _transactionRepository;
  final IdGenerator _idGenerator;
  final TransactionCanBeCreatedSpecification _specification;

  @override
  Future<Result<Transaction>> execute(AddExpenseInput input) async {
    try {
      final validation = await _specification.check(
        input.accountId,
        workspaceId: input.workspaceId,
        currency: input.amount.currency,
      );
      if (validation.isInvalid) {
        return Result.failure(validation.toFinanceException());
      }

      final now = DateTime.now();
      final transaction = Transaction(
        id: TransactionId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        accountId: input.accountId,
        type: TransactionType.expense,
        amount: input.amount,
        categoryId: input.categoryId,
        payee: input.payee,
        note: input.note,
        date: input.date,
        attachmentIds: input.attachmentIds,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _transactionRepository.save(transaction);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(transaction);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
