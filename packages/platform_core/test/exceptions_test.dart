import 'package:platform_core/exceptions/app_exception.dart';
import 'package:platform_core/exceptions/configuration_exception.dart';
import 'package:platform_core/exceptions/unknown_exception.dart';
import 'package:platform_core/exceptions/validation_exception.dart';
import 'package:test/test.dart';

void main() {
  group('AppException', () {
    test('is an Exception', () {
      const e = UnknownException(message: 'x');
      expect(e, isA<Exception>());
      expect(e, isA<AppException>());
    });
  });

  group('ValidationException', () {
    test('stores message and field', () {
      const e = ValidationException(message: 'required', field: 'email');
      expect(e.message, 'required');
      expect(e.field, 'email');
    });

    test('field is nullable', () {
      const e = ValidationException(message: 'bad input');
      expect(e.field, isNull);
    });

    test('equality holds for same message and field', () {
      const a = ValidationException(message: 'm', field: 'f');
      const b = ValidationException(message: 'm', field: 'f');
      expect(a, equals(b));
    });

    test('inequality when field differs', () {
      const a = ValidationException(message: 'm', field: 'f1');
      const b = ValidationException(message: 'm', field: 'f2');
      expect(a, isNot(equals(b)));
    });

    test('toString includes field', () {
      const e = ValidationException(message: 'bad', field: 'name');
      expect(e.toString(), contains('name'));
    });
  });

  group('ConfigurationException', () {
    test('stores message and key', () {
      const e = ConfigurationException(message: 'missing', key: 'apiUrl');
      expect(e.message, 'missing');
      expect(e.key, 'apiUrl');
    });

    test('key is nullable', () {
      const e = ConfigurationException(message: 'bad config');
      expect(e.key, isNull);
    });

    test('equality holds for same message and key', () {
      const a = ConfigurationException(message: 'm', key: 'k');
      const b = ConfigurationException(message: 'm', key: 'k');
      expect(a, equals(b));
    });

    test('toString includes key', () {
      const e = ConfigurationException(message: 'error', key: 'timeout');
      expect(e.toString(), contains('timeout'));
    });
  });

  group('UnknownException', () {
    test('has default message', () {
      const e = UnknownException();
      expect(e.message, isNotEmpty);
    });

    test('accepts custom message', () {
      const e = UnknownException(message: 'custom');
      expect(e.message, 'custom');
    });

    test('stores cause', () {
      final cause = Exception('root');
      final e = UnknownException(message: 'wrapper', cause: cause);
      expect(e.cause, cause);
    });

    test('toString contains message', () {
      const e = UnknownException(message: 'oops');
      expect(e.toString(), contains('oops'));
    });
  });
}
