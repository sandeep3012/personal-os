import 'dart:convert';
import 'dart:io';

import 'package:feature_documents/src/data/database/i_document_database_executor.dart';
import 'package:feature_documents/src/data/database/in_memory_document_database_executor.dart';

/// Persists Documents data to a JSON file on disk, so it survives a full app
/// restart — unlike a bare [InMemoryDocumentDatabaseExecutor]. Mirrors Notes'
/// `FileBackedNoteDatabaseExecutor` exactly.
final class FileBackedDocumentDatabaseExecutor implements IDocumentDatabaseExecutor {
  FileBackedDocumentDatabaseExecutor._(this._engine, this._file);

  final InMemoryDocumentDatabaseExecutor _engine;
  final File _file;

  /// The in-memory engine backing this executor. Exposed so
  /// [FileBackedDocumentTransactionRunner] can run a multi-statement unit of
  /// work directly against it and persist once at the end.
  InMemoryDocumentDatabaseExecutor get engine => _engine;

  /// Loads [file]'s existing contents (if any) into a fresh
  /// [InMemoryDocumentDatabaseExecutor] and returns an executor backed by it.
  ///
  /// If [file] does not exist yet (first launch), starts from an empty
  /// store — identical to a fresh [InMemoryDocumentDatabaseExecutor].
  static Future<FileBackedDocumentDatabaseExecutor> open(File file) async {
    final engine = InMemoryDocumentDatabaseExecutor();
    if (await file.exists()) {
      final raw = await file.readAsString();
      if (raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        engine.restore(_decodeSnapshot(decoded));
      }
    }
    return FileBackedDocumentDatabaseExecutor._(engine, file);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?> arguments = const [],
  ]) =>
      _engine.query(sql, arguments);

  @override
  Future<int> execute(String sql, [List<Object?> arguments = const []]) async {
    final result = await _engine.execute(sql, arguments);
    await persist();
    return result;
  }

  /// Writes the engine's current table state to [_file] as JSON.
  ///
  /// Public so [FileBackedDocumentTransactionRunner] can call it exactly once
  /// after a transaction commits or rolls back, instead of once per
  /// statement inside it.
  Future<void> persist() async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(_engine.snapshot()));
  }

  static Map<String, List<Map<String, Object?>>> _decodeSnapshot(
    Map<String, dynamic> decoded,
  ) =>
      {
        for (final entry in decoded.entries)
          entry.key: (entry.value as List)
              .cast<Map<String, dynamic>>()
              .map(Map<String, Object?>.from)
              .toList(),
      };
}
