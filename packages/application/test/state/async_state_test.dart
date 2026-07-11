import 'package:application/application.dart';
import 'package:platform_core/exceptions/app_exception.dart';
import 'package:platform_core/exceptions/unknown_exception.dart';
import 'package:test/test.dart';

const _err = UnknownException(message: 'oops');

void main() {
  group('AsyncState', () {
    group('factories', () {
      test('loading() is a LoadingState', () {
        expect(const AsyncState<int>.loading(), isA<LoadingState<int>>());
      });

      test('success() is a SuccessState', () {
        expect(const AsyncState<int>.success(42), isA<SuccessState<int>>());
      });

      test('error() is an ErrorState', () {
        expect(const AsyncState<int>.error(_err), isA<ErrorState<int>>());
      });
    });

    group('predicates', () {
      test('isLoading is true for LoadingState', () {
        expect(const AsyncState<String>.loading().isLoading, isTrue);
      });

      test('isLoading is false for SuccessState', () {
        expect(const AsyncState<String>.success('x').isLoading, isFalse);
      });

      test('isSuccess is true for SuccessState', () {
        expect(const AsyncState<int>.success(1).isSuccess, isTrue);
      });

      test('isSuccess is false for LoadingState', () {
        expect(const AsyncState<int>.loading().isSuccess, isFalse);
      });

      test('isError is true for ErrorState', () {
        expect(const AsyncState<int>.error(_err).isError, isTrue);
      });

      test('isError is false for SuccessState', () {
        expect(const AsyncState<int>.success(0).isError, isFalse);
      });
    });

    group('accessors', () {
      test('dataOrNull returns data for SuccessState', () {
        expect(const AsyncState<int>.success(99).dataOrNull, 99);
      });

      test('dataOrNull returns null for LoadingState', () {
        expect(const AsyncState<int>.loading().dataOrNull, isNull);
      });

      test('dataOrNull returns null for ErrorState', () {
        expect(const AsyncState<int>.error(_err).dataOrNull, isNull);
      });

      test('errorOrNull returns exception for ErrorState', () {
        const state = AsyncState<int>.error(_err);
        expect(state.errorOrNull, equals(_err));
      });

      test('errorOrNull returns null for SuccessState', () {
        expect(const AsyncState<int>.success(1).errorOrNull, isNull);
      });

      test('errorOrNull returns null for LoadingState', () {
        expect(const AsyncState<int>.loading().errorOrNull, isNull);
      });
    });

    group('when()', () {
      test('invokes loading callback for LoadingState', () {
        final result = const AsyncState<int>.loading().when(
          loading: () => 'loading',
          success: (d) => 'success:$d',
          error: (e) => 'error',
        );
        expect(result, 'loading');
      });

      test('invokes success callback with data', () {
        final result = const AsyncState<int>.success(7).when(
          loading: () => -1,
          success: (d) => d * 2,
          error: (e) => -2,
        );
        expect(result, 14);
      });

      test('invokes error callback with exception', () {
        AppException? captured;
        const AsyncState<int>.error(_err).when(
          loading: () {},
          success: (_) {},
          error: (e) => captured = e,
        );
        expect(captured, equals(_err));
      });
    });

    group('equality', () {
      test('two SuccessStates with same data are equal', () {
        expect(
          const SuccessState<int>(5),
          equals(const SuccessState<int>(5)),
        );
      });

      test('two SuccessStates with different data are not equal', () {
        expect(
          const SuccessState<int>(5),
          isNot(equals(const SuccessState<int>(6))),
        );
      });

      test('two ErrorStates with same exception are equal', () {
        expect(const ErrorState<int>(_err), equals(const ErrorState<int>(_err)));
      });
    });
  });
}
