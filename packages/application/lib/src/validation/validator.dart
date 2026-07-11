import 'package:application/src/validation/validation_result.dart';

/// Contract for a single validation rule applied to values of type [T].
///
/// Validators are composable: combine multiple rules with [CompositeValidator]
/// to validate all constraints in a single pass.
///
/// Example:
/// ```dart
/// final class NonEmptyStringValidator implements Validator<String> {
///   const NonEmptyStringValidator();
///
///   @override
///   ValidationResult validate(String value) {
///     if (value.trim().isEmpty) {
///       return ValidationResult.invalid([
///         const ValidationFailure(message: 'Value must not be empty.'),
///       ]);
///     }
///     return const ValidationResult.valid();
///   }
/// }
/// ```
abstract interface class Validator<T> {
  /// Validates [value] against this rule and returns the result.
  ValidationResult validate(T value);
}
