import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown when user-supplied or system-supplied data fails a validation rule.
///
/// Optionally carries the name of the [field] that failed validation, making
/// it suitable for field-level form error display.
///
/// Example:
/// ```dart
/// if (email.isEmpty) {
///   throw const ValidationException(
///     message: 'Email must not be empty',
///     field: 'email',
///   );
/// }
/// ```
final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    this.field,
    super.cause,
    super.stackTrace,
  });

  /// The name of the field that failed validation, or `null` if not
  /// field-specific.
  final String? field;

  @override
  bool operator ==(Object other) =>
      other is ValidationException &&
      message == other.message &&
      field == other.field &&
      cause == other.cause;

  @override
  int get hashCode => Object.hash(runtimeType, message, field, cause);

  @override
  String toString() {
    final fieldPart = field != null ? ', field: $field' : '';
    return 'ValidationException(message: $message$fieldPart)';
  }
}
