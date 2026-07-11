import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown when [RuntimeBootstrap] encounters an error during startup or
/// shutdown — for example, a module's [onInit] or [onStop] raises an
/// unexpected exception.
final class RuntimeException extends AppException {
  const RuntimeException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'RuntimeException(message: $message)';
}
