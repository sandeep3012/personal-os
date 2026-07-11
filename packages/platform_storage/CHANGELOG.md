## 0.1.0

Sprint 4 — Platform Storage Foundation

- Added `IDatabase`, `DatabaseConfiguration`, `DatabaseConnection` — database lifecycle contract.
- Added `IRepository<TEntity, TId>` — generic CRUD repository contract (create, findById, findAll, update, delete, exists, count).
- Added `ITransaction`, `ITransactionManager` — transaction begin / commit / rollback / execute contract.
- Added `IPreferences` — typed key-value preferences contract (String, int, double, bool, List<String>).
- Added `ISecureStorage` — OS-keychain read / write / delete / deleteAll / exists contract.
- Added `IFileStorage` — binary and text file I/O plus directory management contract.
- Added `Migration`, `MigrationRunner`, `MigrationContext` — versioned schema migration framework.
- Added `StorageResult`, `MigrationResult`, `DatabaseState` — immutable storage models.
- Added `StorageException` hierarchy: `DatabaseException`, `RepositoryException`, `TransactionException`, `PreferencesException`, `SecureStorageException`, `FileStorageException`, `MigrationException`.
- 91 tests passing, zero analyzer issues.
