import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown when a [LifecycleManager] transition is called in an invalid state.
final class LifecycleException extends AppException {
  const LifecycleException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'LifecycleException(message: $message)';
}
