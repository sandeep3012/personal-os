/// Generic input validation helpers.
///
/// Returns `null` on success or an error message string on failure, following
/// the Flutter form validator convention so these can be passed directly to
/// `TextFormField.validator`.
abstract final class ValidationHelpers {
  ValidationHelpers._();

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  // ── String ────────────────────────────────────────────────────────────────

  /// Validates that [value] is not `null` and not blank.
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  /// Validates that [value] does not exceed [max] characters.
  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'Field',
  }) {
    if (value != null && value.length > max) {
      return '$fieldName must be at most $max characters.';
    }
    return null;
  }

  /// Validates that [value] is at least [min] characters long.
  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.length < min) {
      return '$fieldName must be at least $min characters.';
    }
    return null;
  }

  // ── Format ────────────────────────────────────────────────────────────────

  /// Validates that [value] matches a basic email address pattern.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email.';
    return null;
  }

  /// Validates that [value] is a well-formed UUID v4 string.
  static String? uuid(String? value) {
    if (value == null || !_uuidRegex.hasMatch(value)) {
      return 'Invalid ID format.';
    }
    return null;
  }

  // ── Numeric ───────────────────────────────────────────────────────────────

  /// Validates that [value] is a parseable number within [min]..[max].
  static String? numberRange(
    String? value, {
    required num min,
    required num max,
    String fieldName = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final n = num.tryParse(value);
    if (n == null) return '$fieldName must be a number.';
    if (n < min || n > max) return '$fieldName must be between $min and $max.';
    return null;
  }
}
