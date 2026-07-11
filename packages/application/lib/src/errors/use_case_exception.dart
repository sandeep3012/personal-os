import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown when a use-case execution fails for a reason not covered by a more
/// specific exception type.
///
/// [useCase] optionally identifies the use-case class that failed, useful
/// for structured logging.
///
/// Example:
/// ```dart
/// throw UseCaseException(
///   message: 'Failed to load dashboard data.',
///   useCase: 'LoadDashboardUseCase',
///   cause: networkError,
/// );
/// ```
final class UseCaseException extends AppException {
  const UseCaseException({
    required super.message,
    this.useCase,
    super.cause,
    super.stackTrace,
  });

  /// The name of the use case that encountered the failure, or `null` if not
  /// applicable.
  final String? useCase;

  @override
  bool operator ==(Object other) =>
      other is UseCaseException &&
      message == other.message &&
      useCase == other.useCase &&
      cause == other.cause;

  @override
  int get hashCode => Object.hash(runtimeType, message, useCase, cause);

  @override
  String toString() {
    final ucPart = useCase != null ? ', useCase: $useCase' : '';
    return 'UseCaseException(message: $message$ucPart)';
  }
}
