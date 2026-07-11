import 'package:platform_core/exceptions/app_exception.dart';
import 'package:platform_core/exceptions/unknown_exception.dart';
import 'package:platform_core/result/result.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    // ── Construction ────────────────────────────────────────────────────────

    group('Success', () {
      test('factory wraps value', () {
        const result = Result<int>.success(42);
        expect(result, isA<Success<int>>());
        expect((result as Success<int>).value, 42);
      });

      test('isSuccess is true', () {
        expect(const Result<String>.success('ok').isSuccess, isTrue);
      });

      test('isFailure is false', () {
        expect(const Result<String>.success('ok').isFailure, isFalse);
      });

      test('valueOrNull returns value', () {
        expect(const Result<int>.success(7).valueOrNull, 7);
      });

      test('exceptionOrNull returns null', () {
        expect(const Result<int>.success(7).exceptionOrNull, isNull);
      });

      test('equality holds for same value', () {
        expect(
          const Result<int>.success(1),
          equals(const Result<int>.success(1)),
        );
      });

      test('inequality holds for different value', () {
        expect(
          const Result<int>.success(1),
          isNot(equals(const Result<int>.success(2))),
        );
      });

      test('toString contains value', () {
        expect(const Result<int>.success(99).toString(), contains('99'));
      });
    });

    group('Failure', () {
      const exception = UnknownException(message: 'oops');

      test('factory wraps exception', () {
        const result = Result<int>.failure(exception);
        expect(result, isA<Failure<int>>());
        expect((result as Failure<int>).exception, exception);
      });

      test('isFailure is true', () {
        expect(const Result<String>.failure(exception).isFailure, isTrue);
      });

      test('isSuccess is false', () {
        expect(const Result<String>.failure(exception).isSuccess, isFalse);
      });

      test('valueOrNull returns null', () {
        expect(const Result<int>.failure(exception).valueOrNull, isNull);
      });

      test('exceptionOrNull returns exception', () {
        expect(
          const Result<int>.failure(exception).exceptionOrNull,
          exception,
        );
      });

      test('equality holds for same exception', () {
        expect(
          const Result<int>.failure(exception),
          equals(const Result<int>.failure(exception)),
        );
      });

      test('toString contains exception info', () {
        expect(
          const Result<int>.failure(exception).toString(),
          contains('oops'),
        );
      });
    });

    // ── Pattern matching ────────────────────────────────────────────────────

    group('when', () {
      test('calls success branch on Success', () {
        const Result<int> result = Success(10);
        final out = result.when(
          success: (v) => 'got $v',
          failure: (_) => 'error',
        );
        expect(out, 'got 10');
      });

      test('calls failure branch on Failure', () {
        const Result<int> result =
            Failure(UnknownException(message: 'bad'));
        final out = result.when(
          success: (v) => 'ok',
          failure: (e) => 'fail: ${e.message}',
        );
        expect(out, 'fail: bad');
      });
    });

    // ── Transformations ─────────────────────────────────────────────────────

    group('map', () {
      test('transforms value on Success', () {
        const Result<int> r = Success(3);
        expect(r.map((v) => v * 2), equals(const Success(6)));
      });

      test('passes exception through on Failure', () {
        const exception = UnknownException(message: 'e');
        const Result<int> r = Failure(exception);
        final mapped = r.map((v) => v * 2);
        expect(mapped, isA<Failure<int>>());
        expect((mapped as Failure<int>).exception, exception);
      });
    });

    group('flatMap', () {
      test('chains success result', () {
        const Result<int> r = Success(5);
        final out = r.flatMap((v) => Result.success(v + 1));
        expect(out, equals(const Success(6)));
      });

      test('chains failure result', () {
        const Result<int> r = Success(5);
        const inner = UnknownException(message: 'chain fail');
        final out = r.flatMap<String>((_) => const Failure(inner));
        expect(out, isA<Failure<String>>());
      });

      test('skips transform on Failure', () {
        const exception = UnknownException(message: 'e');
        const Result<int> r = Failure(exception);
        var called = false;
        final out = r.flatMap<int>((v) {
          called = true;
          return Result.success(v);
        });
        expect(called, isFalse);
        expect(out, isA<Failure<int>>());
      });
    });

    // ── Side effects ────────────────────────────────────────────────────────

    group('onSuccess', () {
      test('invokes action on Success', () {
        var captured = 0;
        const Result<int> r = Success(42);
        r.onSuccess((v) => captured = v);
        expect(captured, 42);
      });

      test('does not invoke action on Failure', () {
        var called = false;
        const Result<int> r = Failure(UnknownException(message: 'e'));
        r.onSuccess((_) => called = true);
        expect(called, isFalse);
      });

      test('returns original result', () {
        const result = Result<int>.success(1);
        expect(result.onSuccess((_) {}), same(result));
      });
    });

    group('onFailure', () {
      test('invokes action on Failure', () {
        AppException? captured;
        const Result<int> r =
            Failure(UnknownException(message: 'captured'));
        r.onFailure((e) => captured = e);
        expect(captured?.message, 'captured');
      });

      test('does not invoke action on Success', () {
        var called = false;
        const Result<int> r = Success(1);
        r.onFailure((_) => called = true);
        expect(called, isFalse);
      });
    });
  });
}
