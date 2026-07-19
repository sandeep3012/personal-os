import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:platform_core/platform_core.dart';

final class CreateAccountInput {
  const CreateAccountInput({
    required this.workspaceId,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
  });

  final String workspaceId;
  final String name;
  final AccountType type;
  final CurrencyCode currency;
  final Money initialBalance;
}

/// Creates a new Account and persists it via [IAccountRepository].
///
/// Enforces DOC-031 Business Invariant 8: initial balance must be ≥ 0 for
/// non-credit-card account types.
final class CreateAccountUseCase
    implements AsyncUseCase<CreateAccountInput, Account> {
  CreateAccountUseCase({
    required IAccountRepository accountRepository,
    required IdGenerator idGenerator,
  })  : _accountRepository = accountRepository,
        _idGenerator = idGenerator;

  final IAccountRepository _accountRepository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<Account>> execute(CreateAccountInput input) async {
    try {
      if (input.type != AccountType.creditCard &&
          input.initialBalance.amount < Decimal.zero) {
        throw FinanceException(
          message:
              'Initial balance for ${input.type.name} account must be ≥ 0, '
              'got ${input.initialBalance.amount}',
        );
      }

      final now = DateTime.now();
      final account = Account(
        id: AccountId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        name: input.name,
        type: input.type,
        currency: input.currency,
        initialBalance: input.initialBalance,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _accountRepository.save(account);
      if (saveResult.isFailure) return Result.failure(saveResult.exceptionOrNull!);

      return Result.success(account);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
