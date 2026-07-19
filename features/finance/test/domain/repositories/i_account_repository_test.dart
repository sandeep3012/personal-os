import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/repositories/i_account_repository.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

// ── Fake implementation ───────────────────────────────────────────────────────
//
// Exists solely to verify the interface compiles and can be implemented.
// Not a production class.

final class _FakeAccountRepository implements IAccountRepository {
  final List<Account> _store = [];

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

// ── Helpers ───────────────────────────────────────────────────────────────────

Account _account(String id, {String name = 'Test Account', bool isActive = true}) {
  final inr = CurrencyCode('INR');
  return Account(
    id: AccountId(id),
    workspaceId: 'ws-1',
    name: name,
    type: AccountType.savings,
    currency: inr,
    initialBalance: Money(amount: Decimal.zero, currency: inr),
    isActive: isActive,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late IAccountRepository repository;

  setUp(() => repository = _FakeAccountRepository());

  group('IAccountRepository contract', () {
    // ── findAll ───────────────────────────────────────────────────────────────

    test('findAll returns empty list when no accounts exist', () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('save persists an account and findAll returns it', () async {
      await repository.save(_account('acc-1'));

      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const AccountId('acc-1'));
    });

    test('save overwrites an existing account (upsert)', () async {
      await repository.save(_account('acc-4', name: 'Old Name'));
      await repository.save(_account('acc-4', name: 'New Name'));

      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.name, 'New Name');
    });

    // ── findById ──────────────────────────────────────────────────────────────

    test('findById returns the matching account', () async {
      await repository.save(_account('acc-2'));

      final result = await repository.findById(
        const AccountId('acc-2'),
        workspaceId: 'ws-1',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, const AccountId('acc-2'));
    });

    test('findById returns null for unknown id', () async {
      final result = await repository.findById(
        const AccountId('no-such-id'),
        workspaceId: 'ws-1',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    // ── findActive ────────────────────────────────────────────────────────────

    test('findActive returns only active accounts', () async {
      await repository.save(_account('acc-active', isActive: true));
      await repository.save(_account('acc-inactive', isActive: false));

      final result = await repository.findActive(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const AccountId('acc-active'));
    });

    test('findActive returns empty list when all accounts are inactive', () async {
      await repository.save(_account('acc-1', isActive: false));

      final result = await repository.findActive(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('findActive returns empty list when no accounts exist', () async {
      final result = await repository.findActive(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    // ── softDelete ────────────────────────────────────────────────────────────

    test('softDelete removes the account from findAll results', () async {
      await repository.save(_account('acc-3'));
      await repository.softDelete(
        const AccountId('acc-3'),
        workspaceId: 'ws-1',
      );

      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.valueOrNull, isEmpty);
    });

    test('softDelete is idempotent when account does not exist', () async {
      final result = await repository.softDelete(
        const AccountId('never-existed'),
        workspaceId: 'ws-1',
      );
      expect(result.isSuccess, isTrue);
    });

    test('softDelete does not affect other accounts', () async {
      await repository.save(_account('acc-keep'));
      await repository.save(_account('acc-remove'));

      await repository.softDelete(
        const AccountId('acc-remove'),
        workspaceId: 'ws-1',
      );

      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.first.id, const AccountId('acc-keep'));
    });
  });
}
