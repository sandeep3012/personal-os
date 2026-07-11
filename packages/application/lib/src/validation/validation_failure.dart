/// A single validation failure describing why a value did not pass a rule.
///
/// [field] optionally names the input field that failed, making [ValidationFailure]
/// suitable for field-level form error display.
final class ValidationFailure {
  const ValidationFailure({
    required this.message,
    this.field,
  });

  /// Human-readable description of the validation failure.
  final String message;

  /// The name of the field that failed, or `null` if not field-specific.
  final String? field;

  @override
  bool operator ==(Object other) =>
      other is ValidationFailure &&
      message == other.message &&
      field == other.field;

  @override
  int get hashCode => Object.hash(message, field);

  @override
  String toString() {
    final fieldPart = field != null ? ' (field: $field)' : '';
    return 'ValidationFailure: $message$fieldPart';
  }
}
