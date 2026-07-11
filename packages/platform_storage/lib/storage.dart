/// Personal OS Platform Storage
///
/// Defines technology-neutral contracts for all local persistence in Personal
/// OS: structured database access, key-value preferences, OS-keychain secure
/// storage, file I/O, and a schema migration framework.
///
/// ## Architecture
///
/// ```
/// Apps → Features → platform_storage → platform_core
///                                    → platform_runtime
/// ```
///
/// `platform_storage` owns **contracts only** — no concrete database engine,
/// SharedPreferences, flutter_secure_storage, or dart:io file operations exist
/// in this package. Implementations are introduced in a later sprint after an
/// ADR is approved.
///
/// ## Public API
///
/// ```dart
/// import 'package:platform_storage/storage.dart';
/// ```
library;

// Database
export 'package:platform_storage/database/database_barrel.dart';

// Exceptions
export 'package:platform_storage/exceptions/exceptions_barrel.dart';

// File Storage
export 'package:platform_storage/file_storage/file_storage_barrel.dart';

// Migrations
export 'package:platform_storage/migrations/migrations_barrel.dart';

// Models
export 'package:platform_storage/models/models_barrel.dart';

// Preferences
export 'package:platform_storage/preferences/preferences_barrel.dart';

// Repositories
export 'package:platform_storage/repositories/repositories_barrel.dart';

// Secure Storage
export 'package:platform_storage/secure_storage/secure_storage_barrel.dart';

// Transactions
export 'package:platform_storage/transactions/transactions_barrel.dart';
