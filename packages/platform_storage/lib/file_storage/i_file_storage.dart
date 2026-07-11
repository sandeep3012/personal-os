import 'package:platform_core/result/result.dart';

/// Technology-neutral contract for binary and text file operations.
///
/// All paths are abstract strings — the concrete implementation decides
/// whether they map to absolute file-system paths, relative paths within an
/// app sandbox, or URIs. No `dart:io` types are used here so the contract
/// compiles on every platform including web.
///
/// No concrete implementation exists in this package — those are introduced
/// after an ADR selects the appropriate `dart:io` / path-provider strategy.
abstract interface class IFileStorage {
  // ── File operations ───────────────────────────────────────────────────────

  /// Returns the bytes of the file at [path].
  ///
  /// Returns [Result.success(null)] if no file exists at [path].
  Future<Result<List<int>?>> readBytes(String path);

  /// Returns the UTF-8 text content of the file at [path].
  ///
  /// Returns [Result.success(null)] if no file exists at [path].
  Future<Result<String?>> readString(String path);

  /// Writes [bytes] to [path], creating the file if it does not exist and
  /// overwriting any existing content.
  Future<Result<void>> writeBytes(String path, List<int> bytes);

  /// Writes [content] (UTF-8 encoded) to [path], creating the file if it does
  /// not exist and overwriting any existing content.
  Future<Result<void>> writeString(String path, String content);

  /// Deletes the file at [path].
  ///
  /// Returns [Result.success(true)] if a file was deleted,
  /// [Result.success(false)] if no file existed at [path].
  Future<Result<bool>> delete(String path);

  /// Returns `true` if a file (not a directory) exists at [path].
  Future<Result<bool>> exists(String path);

  /// Moves the file from [sourcePath] to [destinationPath].
  ///
  /// Overwrites [destinationPath] if it already exists.
  Future<Result<void>> move(String sourcePath, String destinationPath);

  /// Copies the file from [sourcePath] to [destinationPath].
  ///
  /// Overwrites [destinationPath] if it already exists.
  Future<Result<void>> copy(String sourcePath, String destinationPath);

  // ── Directory operations ──────────────────────────────────────────────────

  /// Creates the directory at [path] and any missing parent directories.
  ///
  /// Safe to call when the directory already exists — returns success.
  Future<Result<void>> createDirectory(String path);

  /// Deletes the directory at [path] and all of its contents recursively.
  ///
  /// Returns [Result.success(true)] if a directory was deleted,
  /// [Result.success(false)] if no directory existed at [path].
  Future<Result<bool>> deleteDirectory(String path);
}
