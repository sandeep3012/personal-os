# platform_storage

Personal OS Platform Storage — technology-neutral persistence contracts.

---

## Responsibilities

`platform_storage` owns **contracts only**:

| Area | What it defines |
|---|---|
| **Database** | `IDatabase`, `DatabaseConfiguration`, `DatabaseConnection` |
| **Repositories** | `IRepository<TEntity, TId>` |
| **Transactions** | `ITransaction`, `ITransactionManager` |
| **Preferences** | `IPreferences` (String / int / double / bool / List\<String\>) |
| **Secure Storage** | `ISecureStorage` (OS-keychain backed) |
| **File Storage** | `IFileStorage` (binary + text, directories) |
| **Migrations** | `Migration`, `MigrationRunner`, `MigrationContext` |
| **Models** | `StorageResult`, `MigrationResult`, `DatabaseState` |

**Explicitly excluded** from this package:

- SQLite / Drift / Isar / Hive — any concrete database engine
- SharedPreferences implementation
- flutter_secure_storage implementation
- dart:io file operations
- Business entities / feature repositories
- Application logic

Concrete implementations are introduced in a later sprint after an ADR is approved.

---

## Dependency Graph

```
Apps
 └─ Features
     └─ platform_storage   ← this package
         ├─ platform_core  (Result, AppException, IModule, ILogger, …)
         └─ platform_runtime (EventBus, ServiceRegistry, LifecycleManager, …)
```

`platform_storage` must **never** depend on:
- Feature packages
- Flutter UI packages
- AI / Search / Timeline / Notifications / Analytics / Finance packages

---

## Public API

```dart
import 'package:platform_storage/storage.dart';
```

### Database

```dart
abstract interface class IDatabase {
  Future<Result<void>> initialize(DatabaseConfiguration configuration);
  Future<Result<DatabaseConnection>> open();
  Future<Result<void>> close();
  Future<Result<void>> delete();
  bool get isOpen;
}

final class DatabaseConfiguration {
  const DatabaseConfiguration({
    required String name,
    int version = 1,
    String? path,
    bool inMemory = false,
    bool readOnly = false,
  });
}
```

### Repository

```dart
abstract interface class IRepository<TEntity, TId> {
  Future<Result<TEntity>>       create(TEntity entity);
  Future<Result<TEntity?>>      findById(TId id);
  Future<Result<List<TEntity>>> findAll();
  Future<Result<TEntity>>       update(TEntity entity);
  Future<Result<bool>>          delete(TId id);
  Future<Result<bool>>          exists(TId id);
  Future<Result<int>>           count();
}
```

Feature packages extend this with filter / pagination APIs specific to their domain:

```dart
// In packages/features/finance:
abstract interface class ITransactionRepository
    extends IRepository<FinanceTransaction, String> {
  Future<Result<List<FinanceTransaction>>> findByDateRange(
    DateTime from, DateTime to,
  );
}
```

### Transactions

```dart
// Wrap multiple writes in a single atomic unit:
final result = await txManager.execute((tx) async {
  await accountRepo.debit(tx, fromId, amount);
  await accountRepo.credit(tx, toId, amount);
  return 'ok';
});
```

### Preferences

```dart
// Store and retrieve typed key-value pairs:
await prefs.setString('theme', 'dark');
final theme = await prefs.getString('theme'); // Result<String?>
```

### Secure Storage

```dart
// OS-keychain / secure enclave backed:
await secureStorage.write('auth_token', token);
final token = await secureStorage.read('auth_token'); // Result<String?>
```

### File Storage

```dart
await fileStorage.writeString('/reports/2025.json', jsonContent);
final content = await fileStorage.readString('/reports/2025.json');
await fileStorage.move('/reports/2025.json', '/archive/2025.json');
```

### Migration Framework

```dart
class CreateUsersTable extends Migration {
  const CreateUsersTable() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE users (
        id   TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP TABLE IF EXISTS users');
  }
}

final runner = MigrationRunner()
  ..register(CreateUsersTable())
  ..register(AddEmailIndex()); // version 2

final result = await runner.migrate(
  context: dbContext,
  fromVersion: 0,
  toVersion: 2,
);
```

---

## Package Boundaries

| Package | Allowed to import `platform_storage`? |
|---|---|
| `platform_core` | No (platform_storage depends on platform_core, not the reverse) |
| `platform_runtime` | No |
| Feature packages | Yes |
| `apps/mobile` | Yes (via feature packages only — prefer not to import directly) |

---

## Design Decisions

1. **Contracts only, no implementations.** Every interface is a pure abstraction. The concrete engine (Drift / Isar / SQLite) can be swapped without touching feature code.

2. **`Result<T>` everywhere.** All async operations return `Result<T>` from `platform_core`. Storage exceptions never propagate as unhandled exceptions beyond the storage layer.

3. **Typed exception hierarchy.** `StorageException` → `DatabaseException` / `RepositoryException` / `TransactionException` / `PreferencesException` / `SecureStorageException` / `FileStorageException` / `MigrationException`. Each layer has a named exception type.

4. **`IRepository<TEntity, TId>` is intentionally minimal.** No filter/sort/pagination API — those are domain-specific and live in feature repositories that extend this interface.

5. **`MigrationRunner` is concrete.** It has no engine-specific code and is fully testable without any database technology.

6. **No `dart:io` in `IFileStorage`.** Plain `String` paths and `List<int>` bytes keep the contract compilable on every platform including web.
