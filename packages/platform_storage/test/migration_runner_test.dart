import 'package:platform_storage/exceptions/storage_exception.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';
import 'package:platform_storage/migrations/migration_runner.dart';
import 'package:test/test.dart';

// ── Fake MigrationContext ─────────────────────────────────────────────────────

final class FakeMigrationContext implements MigrationContext {
  FakeMigrationContext({this.version = 0});

  @override
  final int version;

  final executedStatements = <String>[];

  @override
  Future<void> execute(String statement) async =>
      executedStatements.add(statement);

  @override
  Future<void> executeWithArgs(String statement, List<Object?> arguments) async {
    executedStatements.add('$statement [args: $arguments]');
  }
}

// ── Test migrations ───────────────────────────────────────────────────────────

final class _RecordingMigration extends Migration {
  _RecordingMigration(int version, this.log) : super(version: version);

  final List<String> log;

  @override
  Future<void> up(MigrationContext ctx) async => log.add('v$version:up');

  @override
  Future<void> down(MigrationContext ctx) async => log.add('v$version:down');
}

final class _FailingMigration extends Migration {
  _FailingMigration(int version, {this.failOn = 'up'})
      : super(version: version);

  final String failOn;

  @override
  Future<void> up(MigrationContext ctx) async {
    if (failOn == 'up') throw Exception('up failed');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    if (failOn == 'down') throw Exception('down failed');
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

MigrationRunner _runnerWith(List<Migration> migrations) {
  final runner = MigrationRunner();
  for (final m in migrations) {
    runner.register(m);
  }
  return runner;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeMigrationContext ctx;

  setUp(() => ctx = FakeMigrationContext());

  group('MigrationRunner — register', () {
    test('migrations are sorted by version ascending', () {
      final log = <String>[];
      final runner = _runnerWith([
        _RecordingMigration(3, log),
        _RecordingMigration(1, log),
        _RecordingMigration(2, log),
      ]);

      expect(runner.migrations.map((m) => m.version), [1, 2, 3]);
    });

    test('duplicate version throws MigrationException', () {
      final runner = MigrationRunner()..register(_RecordingMigration(1, []));
      expect(
        () => runner.register(_RecordingMigration(1, [])),
        throwsA(isA<MigrationException>()),
      );
    });

    test('empty runner has empty migrations list', () {
      expect(MigrationRunner().migrations, isEmpty);
    });
  });

  group('MigrationRunner — migrate (forward)', () {
    test('applies migrations in ascending order', () async {
      final log = <String>[];
      final runner = _runnerWith([
        _RecordingMigration(1, log),
        _RecordingMigration(2, log),
        _RecordingMigration(3, log),
      ]);

      final result = await runner.migrate(
        context: ctx,
        fromVersion: 0,
        toVersion: 3,
      );

      expect(result.isSuccess, isTrue);
      expect(log, ['v1:up', 'v2:up', 'v3:up']);
    });

    test('only applies migrations in (fromVersion, toVersion] range', () async {
      final log = <String>[];
      final runner = _runnerWith([
        _RecordingMigration(1, log),
        _RecordingMigration(2, log),
        _RecordingMigration(3, log),
      ]);

      await runner.migrate(context: ctx, fromVersion: 1, toVersion: 2);

      expect(log, ['v2:up']);
    });

    test('returns MigrationResult with applied versions', () async {
      final log = <String>[];
      final runner = _runnerWith([
        _RecordingMigration(1, log),
        _RecordingMigration(2, log),
      ]);

      final result =
          await runner.migrate(context: ctx, fromVersion: 0, toVersion: 2);

      final value = result.valueOrNull!;
      expect(value.appliedVersions, [1, 2]);
      expect(value.fromVersion, 0);
      expect(value.toVersion, 2);
      expect(value.isRollback, isFalse);
      expect(value.hadChanges, isTrue);
      expect(value.stepCount, 2);
    });

    test('already at target version returns empty success result', () async {
      final log = <String>[];
      final runner = _runnerWith([_RecordingMigration(1, log)]);

      final result =
          await runner.migrate(context: ctx, fromVersion: 1, toVersion: 1);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.appliedVersions, isEmpty);
      expect(log, isEmpty);
    });

    test('fromVersion > toVersion returns failure', () async {
      final runner = MigrationRunner();
      final result =
          await runner.migrate(context: ctx, fromVersion: 5, toVersion: 2);

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<MigrationException>());
    });

    test('migration up() failure returns MigrationException', () async {
      final runner = _runnerWith([_FailingMigration(1)]);
      final result =
          await runner.migrate(context: ctx, fromVersion: 0, toVersion: 1);

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<MigrationException>());
    });

    test('no migrations registered but valid range returns empty result',
        () async {
      final result = await MigrationRunner().migrate(
        context: ctx,
        fromVersion: 0,
        toVersion: 3,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.appliedVersions, isEmpty);
    });
  });

  group('MigrationRunner — rollback (down)', () {
    test('applies down() steps in descending order', () async {
      final log = <String>[];
      final runner = _runnerWith([
        _RecordingMigration(1, log),
        _RecordingMigration(2, log),
        _RecordingMigration(3, log),
      ]);

      final result = await runner.rollback(
        context: ctx,
        fromVersion: 3,
        toVersion: 0,
      );

      expect(result.isSuccess, isTrue);
      expect(log, ['v3:down', 'v2:down', 'v1:down']);
    });

    test('only reverts migrations in (toVersion, fromVersion] range', () async {
      final log = <String>[];
      final runner = _runnerWith([
        _RecordingMigration(1, log),
        _RecordingMigration(2, log),
        _RecordingMigration(3, log),
      ]);

      await runner.rollback(context: ctx, fromVersion: 3, toVersion: 2);

      expect(log, ['v3:down']);
    });

    test('returns MigrationResult with isRollback true', () async {
      final log = <String>[];
      final runner = _runnerWith([
        _RecordingMigration(1, log),
        _RecordingMigration(2, log),
      ]);

      final result =
          await runner.rollback(context: ctx, fromVersion: 2, toVersion: 0);

      final value = result.valueOrNull!;
      expect(value.isRollback, isTrue);
      expect(value.appliedVersions, [2, 1]);
    });

    test('fromVersion < toVersion returns failure', () async {
      final result = await MigrationRunner().rollback(
        context: ctx,
        fromVersion: 1,
        toVersion: 3,
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<MigrationException>());
    });

    test('migration down() failure returns MigrationException', () async {
      final runner = _runnerWith([_FailingMigration(1, failOn: 'down')]);
      final result =
          await runner.rollback(context: ctx, fromVersion: 1, toVersion: 0);

      expect(result.isFailure, isTrue);
    });
  });

  group('MigrationContext', () {
    test('FakeMigrationContext records executed statements', () async {
      await ctx.execute('CREATE TABLE foo (id TEXT)');
      await ctx.executeWithArgs(
        'INSERT INTO foo VALUES (?)',
        ['bar'],
      );

      expect(ctx.executedStatements, hasLength(2));
      expect(ctx.executedStatements[0], contains('CREATE TABLE'));
      expect(ctx.executedStatements[1], contains('INSERT'));
    });
  });
}
