import 'package:platform_storage/exceptions/storage_exception.dart';
import 'package:platform_storage/models/database_state.dart';
import 'package:platform_storage/models/migration_result.dart';
import 'package:platform_storage/models/storage_result.dart';
import 'package:test/test.dart';

void main() {
  // ── StorageResult ──────────────────────────────────────────────────────────
  group('StorageResult', () {
    group('success', () {
      test('isSuccess is true, isFailure is false', () {
        const r = StorageResult.success(operationName: 'insert');
        expect(r.isSuccess, isTrue);
        expect(r.isFailure, isFalse);
      });

      test('exception is null', () {
        const r = StorageResult.success(operationName: 'insert');
        expect(r.exception, isNull);
      });

      test('affectedCount is stored', () {
        const r = StorageResult.success(
          operationName: 'insert',
          affectedCount: 5,
        );
        expect(r.affectedCount, 5);
      });

      test('duration is stored', () {
        const d = Duration(milliseconds: 42);
        const r = StorageResult.success(
          operationName: 'query',
          duration: d,
        );
        expect(r.duration, d);
      });

      test('equality holds for identical fields', () {
        const a = StorageResult.success(
          operationName: 'insert',
          affectedCount: 1,
        );
        const b = StorageResult.success(
          operationName: 'insert',
          affectedCount: 1,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('toString contains outcome and operation name', () {
        const r = StorageResult.success(operationName: 'delete');
        expect(r.toString(), contains('success'));
        expect(r.toString(), contains('delete'));
      });
    });

    group('failure', () {
      const ex = DatabaseException(message: 'disk full');

      test('isFailure is true, isSuccess is false', () {
        const r = StorageResult.failure(
          operationName: 'insert',
          exception: ex,
        );
        expect(r.isFailure, isTrue);
        expect(r.isSuccess, isFalse);
      });

      test('exception is stored', () {
        const r = StorageResult.failure(
          operationName: 'insert',
          exception: ex,
        );
        expect(r.exception, same(ex));
      });

      test('equality holds for identical fields', () {
        const a = StorageResult.failure(
          operationName: 'insert',
          exception: ex,
        );
        const b = StorageResult.failure(
          operationName: 'insert',
          exception: ex,
        );
        expect(a, equals(b));
      });
    });
  });

  // ── MigrationResult ────────────────────────────────────────────────────────
  group('MigrationResult', () {
    test('hadChanges is true when appliedVersions is non-empty', () {
      const r = MigrationResult(
        appliedVersions: [1, 2],
        fromVersion: 0,
        toVersion: 2,
        isRollback: false,
      );
      expect(r.hadChanges, isTrue);
      expect(r.stepCount, 2);
    });

    test('hadChanges is false when appliedVersions is empty', () {
      const r = MigrationResult(
        appliedVersions: [],
        fromVersion: 1,
        toVersion: 1,
        isRollback: false,
      );
      expect(r.hadChanges, isFalse);
      expect(r.stepCount, 0);
    });

    test('equality holds for identical fields', () {
      const a = MigrationResult(
        appliedVersions: [1, 2, 3],
        fromVersion: 0,
        toVersion: 3,
        isRollback: false,
      );
      const b = MigrationResult(
        appliedVersions: [1, 2, 3],
        fromVersion: 0,
        toVersion: 3,
        isRollback: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('equality fails for different appliedVersions', () {
      const a = MigrationResult(
        appliedVersions: [1, 2],
        fromVersion: 0,
        toVersion: 2,
        isRollback: false,
      );
      const b = MigrationResult(
        appliedVersions: [1],
        fromVersion: 0,
        toVersion: 2,
        isRollback: false,
      );
      expect(a, isNot(equals(b)));
    });

    test('isRollback is preserved', () {
      const r = MigrationResult(
        appliedVersions: [3, 2],
        fromVersion: 3,
        toVersion: 1,
        isRollback: true,
      );
      expect(r.isRollback, isTrue);
    });

    test('toString mentions fromVersion and toVersion', () {
      const r = MigrationResult(
        appliedVersions: [1],
        fromVersion: 0,
        toVersion: 1,
        isRollback: false,
      );
      expect(r.toString(), contains('0'));
      expect(r.toString(), contains('1'));
    });
  });

  // ── DatabaseState ──────────────────────────────────────────────────────────
  group('DatabaseState', () {
    const state = DatabaseState(
      name: 'personal_os',
      version: 3,
      isOpen: false,
      path: '/data/db',
    );

    test('asOpen() returns copy with isOpen = true', () {
      final opened = state.asOpen();
      expect(opened.isOpen, isTrue);
      expect(opened.name, state.name);
      expect(opened.version, state.version);
      expect(opened.path, state.path);
    });

    test('asClosed() returns copy with isOpen = false', () {
      final opened = state.asOpen();
      final closed = opened.asClosed();
      expect(closed.isOpen, isFalse);
    });

    test('equality holds for identical fields', () {
      const a = DatabaseState(name: 'db', version: 1, isOpen: false);
      const b = DatabaseState(name: 'db', version: 1, isOpen: false);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('isInMemory defaults to false', () {
      const s = DatabaseState(name: 'db', version: 1, isOpen: false);
      expect(s.isInMemory, isFalse);
    });

    test('toString contains name and version', () {
      expect(state.toString(), contains('personal_os'));
      expect(state.toString(), contains('3'));
    });
  });
}
