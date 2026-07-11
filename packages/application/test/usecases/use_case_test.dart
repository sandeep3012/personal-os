import 'package:application/application.dart';
import 'package:platform_core/exceptions/validation_exception.dart';
import 'package:platform_core/result/result.dart';
import 'package:test/test.dart';

// ── Fake sync use case ─────────────────────────────────────────────────────────

final class _DoubleUseCase implements UseCase<int, int> {
  @override
  Result<int> execute(int input) {
    if (input < 0) {
      return const Result.failure(
        ValidationException(message: 'Input must be non-negative'),
      );
    }
    return Result.success(input * 2);
  }
}

// ── Fake async use case ────────────────────────────────────────────────────────

final class _AsyncSquareUseCase implements AsyncUseCase<int, int> {
  @override
  Future<Result<int>> execute(int input) async {
    if (input < 0) {
      return const Result.failure(
        ValidationException(message: 'Input must be non-negative'),
      );
    }
    return Result.success(input * input);
  }
}

// ── Fake no-params use case ───────────────────────────────────────────────────

final class _GetVersionUseCase implements NoParamsUseCase<String> {
  @override
  Future<Result<String>> execute() async => const Result.success('1.0.0');
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('UseCase', () {
    late _DoubleUseCase useCase;

    setUp(() => useCase = _DoubleUseCase());

    test('returns Success for valid input', () {
      final result = useCase.execute(5);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 10);
    });

    test('returns Failure for invalid input', () {
      final result = useCase.execute(-1);
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<ValidationException>());
    });

    test('transforms value via map', () {
      final result = useCase.execute(3).map((v) => '$v');
      expect(result.valueOrNull, '6');
    });
  });

  group('AsyncUseCase', () {
    late _AsyncSquareUseCase useCase;

    setUp(() => useCase = _AsyncSquareUseCase());

    test('returns Success for valid input', () async {
      final result = await useCase.execute(4);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 16);
    });

    test('returns Failure for negative input', () async {
      final result = await useCase.execute(-3);
      expect(result.isFailure, isTrue);
    });

    test('chains flatMap across two async use cases', () async {
      final r1 = await useCase.execute(3);
      final r2 = r1.flatMap((v) => Result.success(v + 1));
      expect(r2.valueOrNull, 10);
    });
  });

  group('NoParamsUseCase', () {
    late _GetVersionUseCase useCase;

    setUp(() => useCase = _GetVersionUseCase());

    test('returns Success with no input', () async {
      final result = await useCase.execute();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, '1.0.0');
    });
  });
}
