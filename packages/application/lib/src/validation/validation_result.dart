import 'package:application/src/validation/validation_failure.dart';

/// The aggregate result of running one or more validators against a value.
///
/// A [ValidationResult] is valid when it holds no [ValidationFailure]s.
/// Merge results from multiple validators with [merge] to collect all failures
/// in a single pass.
///
/// Example:
/// ```dart
/// final result = emailValidator.validate(input)
///     .merge(lengthValidator.validate(input));
///
/// if (result.isInvalid) {
///   for (final f in result.failures) {
///     print(f.message);
///   }
/// }
/// ```
final class ValidationResult {
  const ValidationResult._({required List<ValidationFailure> failures})
      : _failures = failures;

  /// Constructs a valid result (no failures).
  const ValidationResult.valid() : this._(failures: const []);

  /// Constructs an invalid result from one or more [failures].
  ValidationResult.invalid(List<ValidationFailure> failures)
      : this._(failures: List.unmodifiable(failures));

  final List<ValidationFailure> _failures;

  /// Whether this result has no failures.
  bool get isValid => _failures.isEmpty;

  /// Whether this result has at least one failure.
  bool get isInvalid => _failures.isNotEmpty;

  /// An unmodifiable list of all failures, in the order they were added.
  List<ValidationFailure> get failures => _failures;

  /// Returns a new [ValidationResult] combining the failures of `this` and
  /// [other].
  ///
  /// If both are valid, the result is also valid.
  ValidationResult merge(ValidationResult other) {
    if (isValid && other.isValid) return const ValidationResult.valid();
    return ValidationResult.invalid([..._failures, ...other._failures]);
  }

  @override
  bool operator ==(Object other) =>
      other is ValidationResult && _listEquals(_failures, other._failures);

  @override
  int get hashCode => Object.hashAll(_failures);

  @override
  String toString() {
    if (isValid) return 'ValidationResult.valid()';
    return 'ValidationResult.invalid(${_failures.length} failure(s))';
  }

  static bool _listEquals(
    List<ValidationFailure> a,
    List<ValidationFailure> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
