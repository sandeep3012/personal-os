import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown by [ServiceRegistry] when a dependency operation fails.
final class RegistryException extends AppException {
  const RegistryException({
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'RegistryException(message: $message)';
}
