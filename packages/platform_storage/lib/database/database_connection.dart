import 'package:platform_storage/database/database_configuration.dart';

/// Represents an active connection to a database.
///
/// Returned by [IDatabase.open] and passed to callers that need to perform
/// operations within the same session. Opaque to business logic — only the
/// storage layer and concrete [IDatabase] implementations interpret the
/// contained state.
abstract interface class DatabaseConnection {
  /// The configuration used to open this connection.
  DatabaseConfiguration get configuration;

  /// Whether the underlying connection is still valid and usable.
  bool get isOpen;
}
