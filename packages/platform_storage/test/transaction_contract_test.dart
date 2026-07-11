import 'package:platform_core/result/result.dart';
import 'package:platform_storage/exceptions/storage_exception.dart';
import 'package:platform_storage/transactions/i_transaction.dart';
import 'package:platform_storage/transactions/i_transaction_manager.dart';
import 'package:test/test.dart';

// ── Fake transaction ──────────────────────────────────────────────────────────

final class FakeTransaction implements ITransaction {
  bool _active = true;
  final List<String> events;

  FakeTransaction(this.events);

  @override
  bool get isActive => _active;

  @override
  Future<void> commit() async {
    if (!_active) {
      throw const TransactionException(message: 'Transaction already closed');
    }
    _active = false;
    events.add('committed');
  }

  @override
  Future<void> rollback() async {
    if (!_active) return; // idempotent
    _active = false;
    events.add('rolled_back');
  }
}

// ── Fake transaction manager ──────────────────────────────────────────────────

final class FakeTransactionManager implements ITransactionManager {
  final List<String> events = [];

  bool _shouldFailBegin = false;

  void configureBeginToFail() => _shouldFailBegin = true;

  @override
  Future<Result<ITransaction>> begin() async {
    if (_shouldFailBegin) {
      return const Result.failure(
        TransactionException(message: 'Failed to begin transaction'),
      );
    }
    events.add('begun');
    return Result.success(FakeTransaction(events));
  }

  @override
  Future<Result<T>> execute<T>(
    Future<T> Function(ITransaction transaction) action,
  ) async {
    final beginResult = await begin();
    if (beginResult.isFailure) {
      return Result.failure(beginResult.exceptionOrNull!);
    }

    final tx = beginResult.valueOrNull!;
    try {
      final value = await action(tx);
      await tx.commit();
      return Result.success(value);
    } catch (e, st) {
      await tx.rollback();
      return Result.failure(
        TransactionException(
          message: 'Transaction rolled back: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeTransactionManager manager;

  setUp(() => manager = FakeTransactionManager());

  group('ITransaction', () {
    test('isActive is true before commit', () async {
      final result = await manager.begin();
      final tx = result.valueOrNull! as FakeTransaction;
      expect(tx.isActive, isTrue);
    });

    test('isActive is false after commit', () async {
      final result = await manager.begin();
      final tx = result.valueOrNull!;
      await tx.commit();
      expect(tx.isActive, isFalse);
    });

    test('isActive is false after rollback', () async {
      final result = await manager.begin();
      final tx = result.valueOrNull!;
      await tx.rollback();
      expect(tx.isActive, isFalse);
    });

    test('rollback is idempotent (no throw on double call)', () async {
      final result = await manager.begin();
      final tx = result.valueOrNull!;
      await tx.rollback();
      expect(tx.rollback, returnsNormally);
    });
  });

  group('ITransactionManager — begin', () {
    test('returns an active transaction', () async {
      final result = await manager.begin();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.isActive, isTrue);
    });

    test('records begin event', () async {
      await manager.begin();
      expect(manager.events, contains('begun'));
    });

    test('returns failure when begin fails', () async {
      manager.configureBeginToFail();
      final result = await manager.begin();
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TransactionException>());
    });
  });

  group('ITransactionManager — execute', () {
    test('commits on successful action', () async {
      final result = await manager.execute<String>((tx) async => 'done');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 'done');
      expect(manager.events, containsAllInOrder(['begun', 'committed']));
    });

    test('rolls back on thrown action', () async {
      final result = await manager.execute<String>((tx) async {
        throw Exception('action failed');
      });
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<TransactionException>());
      expect(manager.events, containsAllInOrder(['begun', 'rolled_back']));
    });

    test('returns failure when begin fails', () async {
      manager.configureBeginToFail();
      final result = await manager.execute<int>((tx) async => 42);
      expect(result.isFailure, isTrue);
    });

    test('passes the transaction to the action', () async {
      ITransaction? captured;
      await manager.execute<void>((tx) async => captured = tx);
      expect(captured, isNotNull);
      expect(captured!.isActive, isFalse); // committed after execute
    });
  });
}
