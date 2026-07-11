import 'package:platform_core/result/result.dart';

/// Technology-neutral contract for persisting simple key-value preferences.
///
/// Supported value types: [String], [int], [double], [bool], [List<String>].
/// No concrete implementation (e.g. `SharedPreferences`) exists in this
/// package — those arrive in a later sprint after an ADR is approved.
///
/// All mutating operations return [Result<void>] and reads return
/// [Result<T?>] (nullable because a key may not be set).
abstract interface class IPreferences {
  // ── Reads ─────────────────────────────────────────────────────────────────

  /// Returns the [String] stored under [key], or `null` if not set.
  Future<Result<String?>> getString(String key);

  /// Returns the [int] stored under [key], or `null` if not set.
  Future<Result<int?>> getInt(String key);

  /// Returns the [double] stored under [key], or `null` if not set.
  Future<Result<double?>> getDouble(String key);

  /// Returns the [bool] stored under [key], or `null` if not set.
  Future<Result<bool?>> getBool(String key);

  /// Returns the `List<String>` stored under [key], or `null` if not set.
  Future<Result<List<String>?>> getStringList(String key);

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Stores [value] under [key].
  Future<Result<void>> setString(String key, String value);

  /// Stores [value] under [key].
  Future<Result<void>> setInt(String key, int value);

  /// Stores [value] under [key].
  Future<Result<void>> setDouble(String key, double value);

  /// Stores [value] under [key].
  Future<Result<void>> setBool(String key, bool value);

  /// Stores [value] under [key].
  Future<Result<void>> setStringList(String key, List<String> value);

  // ── Key management ────────────────────────────────────────────────────────

  /// Removes the value stored under [key].
  ///
  /// Safe to call when [key] is not present — returns success.
  Future<Result<void>> remove(String key);

  /// Removes all stored key-value pairs.
  Future<Result<void>> clear();

  /// Returns `true` if [key] has an associated value.
  Future<Result<bool>> containsKey(String key);
}
