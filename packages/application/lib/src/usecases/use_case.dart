import 'package:platform_core/result/result.dart';

/// Base interface for synchronous use cases.
///
/// Prefer [AsyncUseCase] for I/O-bound operations. Use [UseCase] only when
/// the operation is guaranteed to be fast and non-blocking.
///
/// [Input] is the parameter type passed to [execute].
/// [Output] is the type wrapped in [Result] on success.
///
/// Example:
/// ```dart
/// final class FormatCurrencyUseCase implements UseCase<double, String> {
///   @override
///   Result<String> execute(double input) {
///     if (input < 0) {
///       return Result.failure(
///         const ValidationException(message: 'Amount must be non-negative'),
///       );
///     }
///     return Result.success(input.toStringAsFixed(2));
///   }
/// }
/// ```
abstract interface class UseCase<Input, Output> {
  /// Executes the use case with [input] and returns a [Result].
  Result<Output> execute(Input input);
}
