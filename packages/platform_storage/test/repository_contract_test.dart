import 'package:platform_core/result/result.dart';
import 'package:platform_storage/exceptions/storage_exception.dart';
import 'package:platform_storage/repositories/i_repository.dart';
import 'package:test/test.dart';

// ── Minimal entity for testing ────────────────────────────────────────────────

final class User {
  const User({required this.id, required this.name});
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is User && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

// ── In-memory fake ────────────────────────────────────────────────────────────

final class InMemoryUserRepository implements IRepository<User, String> {
  final _store = <String, User>{};
  bool _shouldFail = false;

  void configureToFail() => _shouldFail = true;

  Result<T> _fail<T>() => const Result.failure(
        RepositoryException(message: 'Simulated repository failure'),
      );

  @override
  Future<Result<User>> create(User entity) async {
    if (_shouldFail) return _fail();
    _store[entity.id] = entity;
    return Result.success(entity);
  }

  @override
  Future<Result<User?>> findById(String id) async {
    if (_shouldFail) return _fail();
    return Result.success(_store[id]);
  }

  @override
  Future<Result<List<User>>> findAll() async {
    if (_shouldFail) return _fail();
    return Result.success(_store.values.toList());
  }

  @override
  Future<Result<User>> update(User entity) async {
    if (_shouldFail) return _fail();
    if (!_store.containsKey(entity.id)) {
      return const Result.failure(
        RepositoryException(message: 'Entity not found'),
      );
    }
    _store[entity.id] = entity;
    return Result.success(entity);
  }

  @override
  Future<Result<bool>> delete(String id) async {
    if (_shouldFail) return _fail();
    final removed = _store.remove(id);
    return Result.success(removed != null);
  }

  @override
  Future<Result<bool>> exists(String id) async {
    if (_shouldFail) return _fail();
    return Result.success(_store.containsKey(id));
  }

  @override
  Future<Result<int>> count() async {
    if (_shouldFail) return _fail();
    return Result.success(_store.length);
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late InMemoryUserRepository repo;

  const alice = User(id: 'u1', name: 'Alice');
  const bob = User(id: 'u2', name: 'Bob');

  setUp(() => repo = InMemoryUserRepository());

  group('IRepository — create', () {
    test('returns the created entity', () async {
      final result = await repo.create(alice);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, alice);
    });

    test('entity is retrievable after creation', () async {
      await repo.create(alice);
      final found = await repo.findById(alice.id);
      expect(found.valueOrNull, alice);
    });

    test('returns failure on simulated error', () async {
      repo.configureToFail();
      final result = await repo.create(alice);
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<RepositoryException>());
    });
  });

  group('IRepository — findById', () {
    test('returns null when entity does not exist', () async {
      final result = await repo.findById('nonexistent');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('returns entity when it exists', () async {
      await repo.create(alice);
      final result = await repo.findById(alice.id);
      expect(result.valueOrNull, alice);
    });
  });

  group('IRepository — findAll', () {
    test('returns empty list when repository is empty', () async {
      final result = await repo.findAll();
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all entities after multiple creates', () async {
      await repo.create(alice);
      await repo.create(bob);
      final result = await repo.findAll();
      expect(result.valueOrNull, containsAll([alice, bob]));
      expect(result.valueOrNull!.length, 2);
    });
  });

  group('IRepository — update', () {
    test('replaces entity and returns updated version', () async {
      await repo.create(alice);
      const updated = User(id: 'u1', name: 'Alice Smith');
      final result = await repo.update(updated);
      expect(result.valueOrNull, updated);
    });

    test('updated entity is returned by findById', () async {
      await repo.create(alice);
      const updated = User(id: 'u1', name: 'Alice Smith');
      await repo.update(updated);
      final found = await repo.findById('u1');
      expect(found.valueOrNull, updated);
    });

    test('returns failure when entity does not exist', () async {
      final result = await repo.update(alice);
      expect(result.isFailure, isTrue);
    });
  });

  group('IRepository — delete', () {
    test('returns true when entity is deleted', () async {
      await repo.create(alice);
      final result = await repo.delete(alice.id);
      expect(result.valueOrNull, isTrue);
    });

    test('returns false when entity did not exist', () async {
      final result = await repo.delete('missing');
      expect(result.valueOrNull, isFalse);
    });

    test('entity is no longer findable after deletion', () async {
      await repo.create(alice);
      await repo.delete(alice.id);
      final found = await repo.findById(alice.id);
      expect(found.valueOrNull, isNull);
    });
  });

  group('IRepository — exists', () {
    test('returns false before creation', () async {
      final result = await repo.exists(alice.id);
      expect(result.valueOrNull, isFalse);
    });

    test('returns true after creation', () async {
      await repo.create(alice);
      final result = await repo.exists(alice.id);
      expect(result.valueOrNull, isTrue);
    });

    test('returns false after deletion', () async {
      await repo.create(alice);
      await repo.delete(alice.id);
      final result = await repo.exists(alice.id);
      expect(result.valueOrNull, isFalse);
    });
  });

  group('IRepository — count', () {
    test('returns 0 for empty repository', () async {
      final result = await repo.count();
      expect(result.valueOrNull, 0);
    });

    test('increments with each creation', () async {
      await repo.create(alice);
      await repo.create(bob);
      final result = await repo.count();
      expect(result.valueOrNull, 2);
    });

    test('decrements after deletion', () async {
      await repo.create(alice);
      await repo.delete(alice.id);
      final result = await repo.count();
      expect(result.valueOrNull, 0);
    });
  });
}
