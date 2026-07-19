import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/schema/finance_schema.dart';

/// A genuine (if minimal) in-memory relational engine for
/// [IFinanceDatabaseExecutor], built specifically to understand the exact
/// SQL shapes `AccountDao`/`TransactionDao` emit (not a general SQL parser).
///
/// This is the Finance feature's default persistence until a concrete
/// storage engine (Drift, Isar, SQLite, etc.) is approved via ADR — see
/// `IDatabase`'s docstring in `platform_storage`. It genuinely stores rows
/// and evaluates `WHERE`/`ORDER BY`/`LIMIT OFFSET` against them (unlike a
/// call-recording test fake), so the Finance feature is fully usable —
/// data simply does not survive an app restart. The app layer
/// (`apps/mobile`) is responsible for registering this (or a future real
/// engine) before any Finance repository is resolved; `FinanceModule`
/// itself intentionally does not self-register it (see
/// `FinanceModule.registerServices` docs).
final class InMemoryFinanceDatabaseExecutor implements IFinanceDatabaseExecutor {
  final Map<String, List<Map<String, Object?>>> _tables = {
    FinanceSchema.accountsTable: <Map<String, Object?>>[],
    FinanceSchema.transactionsTable: <Map<String, Object?>>[],
  };

  /// When set, the next `INSERT` whose 0-based call index matches
  /// [throwOnInsertCallIndex] throws [insertError] instead of writing —
  /// used by tests to simulate a mid-transfer failure.
  Object? insertError;
  int? throwOnInsertCallIndex;
  var _insertCallIndex = 0;

  // ── Snapshot / restore (backs InMemoryFinanceTransactionRunner) ──────────

  Map<String, List<Map<String, Object?>>> snapshot() => {
        for (final entry in _tables.entries)
          entry.key: entry.value.map(Map<String, Object?>.of).toList(),
      };

  void restore(Map<String, List<Map<String, Object?>>> snapshot) {
    _tables
      ..clear()
      ..addAll(snapshot);
  }

  // ── IFinanceDatabaseExecutor ──────────────────────────────────────────────

  @override
  Future<int> execute(String sql, [List<Object?> arguments = const []]) async {
    final trimmed = sql.trim();
    if (trimmed.startsWith('INSERT INTO')) return _insert(sql, arguments);
    if (trimmed.startsWith('UPDATE')) return _update(sql, arguments);
    throw UnsupportedError('InMemoryFinanceDatabaseExecutor: unrecognized '
        'execute() statement: $sql');
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?> arguments = const [],
  ]) async {
    final trimmed = sql.trim();
    if (trimmed.contains(' JOIN ')) return _transferPairJoin(arguments);
    if (trimmed.startsWith('SELECT COUNT')) return _count(sql, arguments);
    if (trimmed.startsWith('SELECT 1')) return _exists(sql, arguments);
    if (trimmed.startsWith('SELECT *')) return _selectStar(sql, arguments);
    throw UnsupportedError('InMemoryFinanceDatabaseExecutor: unrecognized '
        'query() statement: $sql');
  }

  // ── Statement handlers ────────────────────────────────────────────────────

  int _insert(String sql, List<Object?> args) {
    final callIndex = _insertCallIndex++;
    if (insertError != null &&
        (throwOnInsertCallIndex == null || throwOnInsertCallIndex == callIndex)) {
      throw insertError!;
    }

    final table = _tables[_tableNameOf(sql)]!;
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
    final table = _tables[_tableNameOf(sql)]!;
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
    final table = _tables[_tableNameOf(sql)]!;
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
    final table = _tables[_tableNameOf(sql)]!;
    final whereClause =
        RegExp(r'WHERE (.+)$').firstMatch(sql)!.group(1)!.trim();
    final count =
        table.where((row) => _rowMatches(row, whereClause, args)).length;
    return [
      {'total': count},
    ];
  }

  List<Map<String, Object?>> _exists(String sql, List<Object?> args) {
    final table = _tables[_tableNameOf(sql)]!;
    final whereClause =
        RegExp(r'WHERE (.+?) LIMIT').firstMatch(sql)!.group(1)!.trim();
    final matched = table.any((row) => _rowMatches(row, whereClause, args));
    return matched
        ? [
            {'1': 1},
          ]
        : const [];
  }

  List<Map<String, Object?>> _transferPairJoin(List<Object?> args) {
    final table = _tables[FinanceSchema.transactionsTable]!;
    final transactionId = args[0];
    final workspaceId = args[1];

    final leg = table.where((row) =>
        row[FinanceSchema.transactionId] == transactionId &&
        row[FinanceSchema.transactionWorkspaceId] == workspaceId);
    if (leg.isEmpty) return const [];

    final pairId = leg.first[FinanceSchema.transactionTransferPairId];
    if (pairId == null) return const [];

    final counterpart = table.where((row) =>
        row[FinanceSchema.transactionId] == pairId &&
        row[FinanceSchema.transactionDeletedAt] == null);
    return counterpart.isEmpty
        ? const []
        : [Map<String, Object?>.of(counterpart.first)];
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
      } else if (fragment.contains('>=')) {
        final column = fragment.split('>=')[0].trim();
        final value = args[argIndex++];
        if (_compare(row[column], value) < 0) matches = false;
      } else if (fragment.contains('<=')) {
        final column = fragment.split('<=')[0].trim();
        final value = args[argIndex++];
        if (_compare(row[column], value) > 0) matches = false;
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

  String _tableNameOf(String sql) => sql.contains(FinanceSchema.transactionsTable)
      ? FinanceSchema.transactionsTable
      : FinanceSchema.accountsTable;
}
