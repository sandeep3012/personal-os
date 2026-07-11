import 'package:platform_core/result/result.dart';

/// Technology-neutral contract for OS-keychain / secure enclave backed storage.
///
/// All values are stored as [String]. Callers are responsible for serialising
/// structured data before writing and deserialising after reading. No concrete
/// implementation (`flutter_secure_storage`, etc.) exists in this package.
///
/// Keys are scoped to the application by the concrete implementation — callers
/// should not embed app-level namespacing in the key.
abstract interface class ISecureStorage {
  /// Returns the value stored under [key], or `null` if the key is not set.
  Future<Result<String?>> read(String key);

  /// Stores [value] under [key].
  ///
  /// Overwrites any previously stored value for the same [key].
  Future<Result<void>> write(String key, String value);

  /// Deletes the value stored under [key].
  ///
  /// Safe to call when [key] is not present — returns success.
  Future<Result<void>> delete(String key);

  /// Deletes all key-value pairs from secure storage.
  Future<Result<void>> deleteAll();

  /// Returns `true` if [key] has an associated value.
  Future<Result<bool>> exists(String key);
}
