import 'package:feature_tasks/src/data/database/i_task_database_executor.dart';
import 'package:feature_tasks/src/data/schema/tasks_schema.dart';

/// A genuine (if minimal) in-memory relational engine for
/// [ITaskDatabaseExecutor], built specifically to understand the exact SQL
/// shapes [TaskDao] emits — mirrors Finance's
/// `InMemoryFinanceDatabaseExecutor` exactly, scoped to Tasks' single table
/// (no transfer-pair-style JOIN handling is needed here).
///
/// This is the Tasks feature's default persistence until a concrete storage
/// engine (Drift, Isar, SQLite, etc.) is approved via ADR — same status as
/// Finance's equivalent. It genuinely stores rows and evaluates
/// `WHERE`/`ORDER BY`/`LIMIT OFFSET` against them, so the Tasks feature is
/// fully usable — data simply does not survive an app restart on its own
/// (see `FileBackedTaskDatabaseExecutor` for that).
final class InMemoryTaskDatabaseExecutor implements ITaskDatabaseExecutor {
  final Map<String, List<Map<String, Object?>>> _tables = {
    TasksSchema.tasksTable: <Map<String, Object?>>[],
  };

  /// When set, the next `INSERT` whose 0-based call index matches
  /// [throwOnInsertCallIndex] throws [insertError] instead of writing —
  /// used by tests to simulate a mid-write failure.
  Object? insertError;
  int? throwOnInsertCallIndex;
  var _insertCallIndex = 0;

  // ── Snapshot / restore (backs InMemoryTaskTransactionRunner) ─────────────

  Map<String, List<Map<String, Object?>>> snapshot() => {
        for (final entry in _tables.entries)
          entry.key: entry.value.map(Map<String, Object?>.of).toList(),
      };

  void restore(Map<String, List<Map<String, Object?>>> snapshot) {
    _tables
      ..clear()
      ..addAll(snapshot);
  }

  // ── ITaskDatabaseExecutor ─────────────────────────────────────────────────

  @override
  Future<int> execute(String sql, [List<Object?> arguments = const []]) async {
    final trimmed = sql.trim();
    if (trimmed.startsWith('INSERT INTO')) return _insert(sql, arguments);
    if (trimmed.startsWith('UPDATE')) return _update(sql, arguments);
    throw UnsupportedError('InMemoryTaskDatabaseExecutor: unrecognized '
        'execute() statement: $sql');
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?> arguments = const [],
  ]) async {
    final trimmed = sql.trim();
    if (trimmed.startsWith('SELECT COUNT')) return _count(sql, arguments);
    if (trimmed.startsWith('SELECT 1')) return _exists(sql, arguments);
    if (trimmed.startsWith('SELECT *')) return _selectStar(sql, arguments);
    throw UnsupportedError('InMemoryTaskDatabaseExecutor: unrecognized '
        'query() statement: $sql');
  }

  // ── Statement handlers ────────────────────────────────────────────────────

  int _insert(String sql, List<Object?> args) {
    final callIndex = _insertCallIndex++;
    if (insertError != null &&
        (throwOnInsertCallIndex == null || throwOnInsertCallIndex == callIndex)) {
      throw insertError!;
    }

    final table = _tables[TasksSchema.tasksTable]!;
    final columns = RegExp(r'\((.+?)\) VALUES')
        .firstMatch(sql)!
        .group(1)!
        .split(', ')
        .map((c) => c.trim())
        .toList();

    final row = <String, Object?>{
      for (var i = 0; i < columns.length; i++) columns[i]: args[i],
    };
    table.add(row);
    return 1;
  }

  int _update(String sql, List<Object?> args) {
    final table = _tables[TasksSchema.tasksTable]!;
    final setColumns = RegExp(r'SET (.+) WHERE')
        .firstMatch(sql)!
        .group(1)!
        .split(', ')
        .map((f) => f.split('=')[0].trim())
        .toList();
    final setArgs = args.sublist(0, setColumns.length);
    final whereArgs = args.sublist(setColumns.length);
    final whereClause =
        RegExp(r'WHERE (.+)$').firstMatch(sql)!.group(1)!.trim();

    var affected = 0;
    for (final row in table) {
      if (_rowMatches(row, whereClause, whereArgs)) {
        for (var i = 0; i < setColumns.length; i++) {
          row[setColumns[i]] = setArgs[i];
        }
        affected++;
      }
    }
    return affected;
  }

  List<Map<String, Object?>> _selectStar(String sql, List<Object?> args) {
    final table = _tables[TasksSchema.tasksTable]!;
    final whereClause = RegExp(r'WHERE (.+?)(?: ORDER BY| LIMIT|$)')
        .firstMatch(sql)!
        .group(1)!
        .trim();
    final whereArgCount = _placeholderCount(whereClause);
    final whereArgs = args.sublist(0, whereArgCount);

    var results = table
        .where((row) => _rowMatches(row, whereClause, whereArgs))
        .map(Map<String, Object?>.of)
        .toList();

    final orderMatch = RegExp(r'ORDER BY (\w+)(?: (ASC|DESC))?').firstMatch(sql);
    if (orderMatch != null) {
      final column = orderMatch.group(1)!;
      final descending = orderMatch.group(2) == 'DESC';
      results.sort((a, b) {
        final cmp = _compare(a[column], b[column]);
        return descending ? -cmp : cmp;
      });
    }

    if (sql.contains('LIMIT ?')) {
      final limit = args[args.length - 2]! as int;
      final offset = args[args.length - 1]! as int;
      results = results.skip(offset).take(limit).toList();
    }

    return results;
  }

  List<Map<String, Object?>> _count(String sql, List<Object?> args) {
    final table = _tables[TasksSchema.tasksTable]!;
    final whereClause =
        RegExp(r'WHERE (.+)$').firstMatch(sql)!.group(1)!.trim();
    final count =
        table.where((row) => _rowMatches(row, whereClause, args)).length;
    return [
      {'total': count},
    ];
  }

  List<Map<String, Object?>> _exists(String sql, List<Object?> args) {
    final table = _tables[TasksSchema.tasksTable]!;
    final whereClause =
        RegExp(r'WHERE (.+?) LIMIT').firstMatch(sql)!.group(1)!.trim();
    final matched = table.any((row) => _rowMatches(row, whereClause, args));
    return matched
        ? [
            {'1': 1},
          ]
        : const [];
  }

  // ── WHERE-clause evaluation ───────────────────────────────────────────────

  bool _rowMatches(
    Map<String, Object?> row,
    String whereClause,
    List<Object?> args,
  ) {
    var argIndex = 0;
    var matches = true;
    for (final rawFragment in whereClause.split(' AND ')) {
      final fragment = rawFragment.trim();
      if (fragment.endsWith('IS NULL')) {
        final column = fragment.substring(0, fragment.length - 7).trim();
        if (row[column] != null) matches = false;
      } else if (fragment.endsWith('IS NOT NULL')) {
        final column = fragment.substring(0, fragment.length - 11).trim();
        if (row[column] == null) matches = false;
      } else if (fragment.startsWith('LOWER(')) {
        final column = RegExp(r'LOWER\((\w+)\)').firstMatch(fragment)!.group(1)!;
        final pattern = args[argIndex++]! as String;
        final needle = pattern.substring(1, pattern.length - 1); // strip %..%
        final cell = (row[column] as String?)?.toLowerCase() ?? '';
        if (!cell.contains(needle)) matches = false;
      } else if (fragment.contains('=')) {
        final parts = fragment.split('=');
        final column = parts[0].trim();
        final rhs = parts[1].trim();
        final value = rhs == '?' ? args[argIndex++] : int.parse(rhs);
        if (row[column] != value) matches = false;
      }
    }
    return matches;
  }

  int _placeholderCount(String whereClause) =>
      whereClause.split('?').length - 1;

  int _compare(Object? a, Object? b) {
    if (a is String && b is String) return a.compareTo(b);
    if (a is int && b is int) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }
}
