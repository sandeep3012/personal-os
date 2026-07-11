import 'package:platform_core/result/result.dart';

/// Generic CRUD contract for a single entity type.
///
/// [TEntity] is the domain entity; [TId] is its identifier type (typically
/// [String] for UUID-keyed entities or [int] for auto-increment keys).
///
/// No filtering, pagination, or sorting API is defined here — those belong in
/// feature-specific repository extensions added in later sprints.
///
/// All operations return [Result] so use-case callers deal with structured
/// [AppException]s rather than catching raw exceptions.
///
/// Example:
/// ```dart
/// abstract interface class ITransactionRepository
///     extends IRepository<Transaction, String> {
///   // feature-specific queries go here
/// }
/// ```
abstract interface class IRepository<TEntity, TId> {
  /// Persists [entity] and returns the saved entity (which may include
  /// server-assigned values such as an id or timestamps).
  Future<Result<TEntity>> create(TEntity entity);

  /// Retrieves the entity with the given [id].
  ///
  /// Returns [Result.success(null)] when no entity with [id] exists.
  Future<Result<TEntity?>> findById(TId id);

  /// Returns every entity in the repository.
  ///
  /// For large data sets prefer a paginated variant defined in the concrete
  /// subtype. This method is intentionally simple and suitable only for small
  /// collections or tests.
  Future<Result<List<TEntity>>> findAll();

  /// Updates an existing entity in the repository.
  ///
  /// Returns the updated entity. Throws (via [Result.failure]) if no entity
  /// with the matching id exists.
  Future<Result<TEntity>> update(TEntity entity);

  /// Deletes the entity with the given [id].
  ///
  /// Returns [Result.success(true)] if an entity was deleted,
  /// [Result.success(false)] if no entity with [id] existed.
  Future<Result<bool>> delete(TId id);

  /// Returns `true` if an entity with [id] exists in the repository.
  Future<Result<bool>> exists(TId id);

  /// Returns the total number of entities in the repository.
  Future<Result<int>> count();
}
