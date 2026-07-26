import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/create_account_use_case.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../../../helpers/fake_account_repository.dart';

// ── Stub IdGenerator ──────────────────────────────────────────────────────────

final class _FixedIdGenerator implements IdGenerator {
  int _i = 0;
  @override
  String generate() => 'acc-${++_i}';
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _inr = CurrencyCode('INR');

Money _money(String amount) =>
    Money(amount: Decimal.parse(amount), currency: _inr);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeAccountRepository repo;
  late CreateAccountUseCase useCase;

  setUp(() {
    repo = FakeAccountRepository();
    useCase = CreateAccountUseCase(
      accountRepository: repo,
      idGenerator: _FixedIdGenerator(),
      specification: AccountCanBeCreatedSpecification(accountRepository: repo),
    );
  });

  group('CreateAccountUseCase', () {
    test('creates and persists a savings account', () async {
      final input = CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'Main Savings',
        type: AccountType.savings,
        currency: _inr,
        initialBalance: _money('5000'),
      );

      final result = await useCase.execute(input);

      expect(result.isSuccess, isTrue);
      final account = result.valueOrNull!;
      expect(account.name, 'Main Savings');
      expect(account.type, AccountType.savings);
      expect(account.isActive, isTrue);
      expect(repo.store, contains(account));
    });

    test('returns generated id for the new account', () async {
      final input = CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'Cash',
        type: AccountType.cash,
        currency: _inr,
        initialBalance: _money('0'),
      );

      final result = await useCase.execute(input);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.id.value, 'acc-1');
    });

    test('allows negative initial balance for credit card', () async {
      final input = CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'Visa',
        type: AccountType.creditCard,
        currency: _inr,
        initialBalance: _money('-1000'),
      );

      final result = await useCase.execute(input);

      expect(result.isSuccess, isTrue);
    });

    test('rejects negative initial balance for savings account', () async {
      final input = CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'Bad Savings',
        type: AccountType.savings,
        currency: _inr,
        initialBalance: _money('-100'),
      );

      final result = await useCase.execute(input);

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });

    test('rejects negative initial balance for checking account', () async {
      final input = CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'Bad Checking',
        type: AccountType.checking,
        currency: _inr,
        initialBalance: _money('-1'),
      );

      final result = await useCase.execute(input);

      expect(result.isFailure, isTrue);
    });

    test('allows zero initial balance for non-credit-card account', () async {
      final input = CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'New Account',
        type: AccountType.checking,
        currency: _inr,
        initialBalance: _money('0'),
      );

      final result = await useCase.execute(input);

      expect(result.isSuccess, isTrue);
    });

    test('rejects a duplicate account name (case-insensitive)', () async {
      await useCase.execute(CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'HDFC Savings',
        type: AccountType.savings,
        currency: _inr,
        initialBalance: _money('0'),
      ));

      final result = await useCase.execute(CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'hdfc savings',
        type: AccountType.savings,
        currency: _inr,
        initialBalance: _money('0'),
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
      expect(repo.store, hasLength(1));
    });

    test('rejects an empty account name', () async {
      final result = await useCase.execute(CreateAccountInput(
        workspaceId: 'ws-1',
        name: '   ',
        type: AccountType.savings,
        currency: _inr,
        initialBalance: _money('0'),
      ));

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<FinanceException>());
    });

    test('rejects an account name over 100 characters', () async {
      final result = await useCase.execute(CreateAccountInput(
        workspaceId: 'ws-1',
        name: 'A' * 101,
        type: AccountType.savings,
        currency: _inr,
        initialBalance: _money('0'),
      ));

      expect(result.isFailure, isTrue);
    });
  });
}
