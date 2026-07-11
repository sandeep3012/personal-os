import 'package:platform_core/exceptions/app_exception.dart';

/// Base class for all storage-layer exceptions in Personal OS.
///
/// Prefer concrete subtypes ([DatabaseException], [RepositoryException],
/// [PreferencesException], [SecureStorageException], [FileStorageException],
/// [MigrationException], [TransactionException]) over catching this directly.
abstract class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when a low-level database operation fails (open, close, query, etc.).
final class DatabaseException extends StorageException {
  const DatabaseException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'DatabaseException(message: $message)';
}

/// Thrown when a repository operation fails (create, read, update, delete).
final class RepositoryException extends StorageException {
  const RepositoryException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'RepositoryException(message: $message)';
}

/// Thrown when a preferences operation fails.
final class PreferencesException extends StorageException {
  const PreferencesException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'PreferencesException(message: $message)';
}

/// Thrown when a secure storage operation fails.
final class SecureStorageException extends StorageException {
  const SecureStorageException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'SecureStorageException(message: $message)';
}

/// Thrown when a file storage operation fails.
final class FileStorageException extends StorageException {
  const FileStorageException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'FileStorageException(message: $message)';
}

/// Thrown when a migration step fails or the migration sequence is invalid.
final class MigrationException extends StorageException {
  const MigrationException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'MigrationException(message: $message)';
}

/// Thrown when a transaction operation fails (begin, commit, rollback).
final class TransactionException extends StorageException {
  const TransactionException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'TransactionException(message: $message)';
}
