import 'package:application/application.dart';
import 'package:test/test.dart';

// ── Fake validators ────────────────────────────────────────────────────────────

final class _NonEmptyValidator implements Validator<String> {
  const _NonEmptyValidator();

  @override
  ValidationResult validate(String value) {
    if (value.trim().isEmpty) {
      return ValidationResult.invalid([
        const ValidationFailure(message: 'Must not be empty', field: 'value'),
      ]);
    }
    return const ValidationResult.valid();
  }
}

final class _MaxLengthValidator implements Validator<String> {
  const _MaxLengthValidator(this._max);
  final int _max;

  @override
  ValidationResult validate(String value) {
    if (value.length > _max) {
      return ValidationResult.invalid([
        ValidationFailure(message: 'Max length is $_max', field: 'value'),
      ]);
    }
    return const ValidationResult.valid();
  }
}

final class _AlwaysInvalidValidator implements Validator<String> {
  const _AlwaysInvalidValidator(this._msg);
  final String _msg;

  @override
  ValidationResult validate(String value) {
    return ValidationResult.invalid([ValidationFailure(message: _msg)]);
  }
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('ValidationFailure', () {
    test('equality holds for same message and field', () {
      expect(
        const ValidationFailure(message: 'a', field: 'f'),
        equals(const ValidationFailure(message: 'a', field: 'f')),
      );
    });

    test('inequality when message differs', () {
      expect(
        const ValidationFailure(message: 'a'),
        isNot(equals(const ValidationFailure(message: 'b'))),
      );
    });

    test('toString includes message', () {
      const f = ValidationFailure(message: 'required', field: 'email');
      expect(f.toString(), contains('required'));
      expect(f.toString(), contains('email'));
    });

    test('field can be null', () {
      const f = ValidationFailure(message: 'error');
      expect(f.field, isNull);
    });
  });

  group('ValidationResult', () {
    test('valid() is valid', () {
      expect(const ValidationResult.valid().isValid, isTrue);
    });

    test('valid() is not invalid', () {
      expect(const ValidationResult.valid().isInvalid, isFalse);
    });

    test('invalid() is invalid', () {
      final r = ValidationResult.invalid([
        const ValidationFailure(message: 'error'),
      ]);
      expect(r.isInvalid, isTrue);
    });

    test('failures list is unmodifiable', () {
      final r = ValidationResult.invalid([
        const ValidationFailure(message: 'a'),
      ]);
      expect(() => r.failures.add(const ValidationFailure(message: 'b')), throwsA(anything));
    });

    test('merge of two valid results is valid', () {
      final merged = const ValidationResult.valid()
          .merge(const ValidationResult.valid());
      expect(merged.isValid, isTrue);
    });

    test('merge of valid + invalid is invalid', () {
      final invalid = ValidationResult.invalid([
        const ValidationFailure(message: 'bad'),
      ]);
      final merged = const ValidationResult.valid().merge(invalid);
      expect(merged.isInvalid, isTrue);
      expect(merged.failures, hasLength(1));
    });

    test('merge accumulates all failures', () {
      final r1 = ValidationResult.invalid([
        const ValidationFailure(message: 'err1'),
      ]);
      final r2 = ValidationResult.invalid([
        const ValidationFailure(message: 'err2'),
        const ValidationFailure(message: 'err3'),
      ]);
      final merged = r1.merge(r2);
      expect(merged.failures, hasLength(3));
    });

    test('toString includes valid/invalid label', () {
      expect(
        const ValidationResult.valid().toString(),
        contains('valid'),
      );
      expect(
        ValidationResult.invalid([const ValidationFailure(message: 'x')])
            .toString(),
        contains('invalid'),
      );
    });
  });

  group('CompositeValidator', () {
    test('is valid when all validators pass', () {
      const validator = CompositeValidator<String>([
        _NonEmptyValidator(),
        _MaxLengthValidator(10),
      ]);
      final result = validator.validate('hello');
      expect(result.isValid, isTrue);
    });

    test('is invalid when one validator fails', () {
      const validator = CompositeValidator<String>([
        _NonEmptyValidator(),
        _MaxLengthValidator(3),
      ]);
      final result = validator.validate('toolong');
      expect(result.isInvalid, isTrue);
    });

    test('accumulates failures from all failing validators', () {
      const validator = CompositeValidator<String>([
        _AlwaysInvalidValidator('err1'),
        _AlwaysInvalidValidator('err2'),
      ]);
      final result = validator.validate('anything');
      expect(result.failures, hasLength(2));
    });

    test('validators returns unmodifiable list', () {
      const v = CompositeValidator<String>(
        [_NonEmptyValidator()],
      );
      expect(
        () => v.validators.add(const _NonEmptyValidator()),
        throwsA(anything),
      );
    });

    test('empty composite is always valid', () {
      final result = const CompositeValidator<String>([]).validate('anything');
      expect(result.isValid, isTrue);
    });
  });
}
