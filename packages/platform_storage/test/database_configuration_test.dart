import 'package:platform_storage/database/database_configuration.dart';
import 'package:test/test.dart';

void main() {
  group('DatabaseConfiguration', () {
    test('default values are applied', () {
      const config = DatabaseConfiguration(name: 'test');
      expect(config.version, 1);
      expect(config.path, isNull);
      expect(config.inMemory, isFalse);
      expect(config.readOnly, isFalse);
    });

    test('all fields are stored correctly', () {
      const config = DatabaseConfiguration(
        name: 'personal_os',
        version: 5,
        path: '/data/personal_os.db',
        inMemory: true,
        readOnly: true,
      );
      expect(config.name, 'personal_os');
      expect(config.version, 5);
      expect(config.path, '/data/personal_os.db');
      expect(config.inMemory, isTrue);
      expect(config.readOnly, isTrue);
    });

    test('equality holds for identical fields', () {
      const a = DatabaseConfiguration(name: 'db', version: 2, path: '/tmp');
      const b = DatabaseConfiguration(name: 'db', version: 2, path: '/tmp');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when name differs', () {
      const a = DatabaseConfiguration(name: 'db_a');
      const b = DatabaseConfiguration(name: 'db_b');
      expect(a, isNot(equals(b)));
    });

    test('inequality when version differs', () {
      const a = DatabaseConfiguration(name: 'db', version: 1);
      const b = DatabaseConfiguration(name: 'db', version: 2);
      expect(a, isNot(equals(b)));
    });

    test('inequality when inMemory differs', () {
      const a = DatabaseConfiguration(name: 'db');
      const b = DatabaseConfiguration(name: 'db', inMemory: true);
      expect(a, isNot(equals(b)));
    });

    test('toString contains name and version', () {
      const config = DatabaseConfiguration(name: 'my_db', version: 3);
      expect(config.toString(), contains('my_db'));
      expect(config.toString(), contains('3'));
    });

    test('version must be >= 1 (assert fires in debug mode)', () {
      // Assertions only fire in debug builds — this test verifies the
      // constraint is declared rather than silently ignored.
      expect(
        () => DatabaseConfiguration(name: 'db', version: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
