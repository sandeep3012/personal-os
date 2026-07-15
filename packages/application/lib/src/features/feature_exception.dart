import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown when a feature-level error occurs — e.g. a feature attempts to
/// register after boot, or a required feature is missing at runtime.
final class FeatureException extends AppException {
  const FeatureException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
