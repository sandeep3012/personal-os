import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown when the application cannot be configured correctly.
///
/// Typical triggers: missing required config values, invalid environment
/// setup, or a feature flag in an inconsistent state.
///
/// Example:
/// ```dart
/// if (config.apiBaseUrl.isEmpty) {
///   throw const ConfigurationException(
///     message: 'apiBaseUrl must not be empty',
///     key: 'apiBaseUrl',
///   );
/// }
/// ```
final class ConfigurationException extends AppException {
  const ConfigurationException({
    required super.message,
    this.key,
    super.cause,
    super.stackTrace,
  });

  /// The configuration key involved in the failure, or `null` if not
  /// key-specific.
  final String? key;

  @override
  bool operator ==(Object other) =>
      other is ConfigurationException &&
      message == other.message &&
      key == other.key &&
      cause == other.cause;

  @override
  int get hashCode => Object.hash(runtimeType, message, key, cause);

  @override
  String toString() {
    final keyPart = key != null ? ', key: $key' : '';
    return 'ConfigurationException(message: $message$keyPart)';
  }
}
