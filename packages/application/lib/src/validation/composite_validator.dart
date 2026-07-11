import 'package:application/src/validation/validation_result.dart';
import 'package:application/src/validation/validator.dart';

/// A [Validator] that runs multiple validators in sequence and merges all
/// results into a single [ValidationResult].
///
/// All validators are always executed — no short-circuit on first failure —
/// so the result accumulates every failing constraint simultaneously.
///
/// Example:
/// ```dart
/// final emailValidator = CompositeValidator<String>([
///   NonEmptyStringValidator(),
///   EmailFormatValidator(),
///   MaxLengthValidator(maxLength: 254),
/// ]);
///
/// final result = emailValidator.validate(userInput);
/// ```
final class CompositeValidator<T> implements Validator<T> {
  const CompositeValidator(this._validators);

  final List<Validator<T>> _validators;

  /// Returns an unmodifiable view of the composed validators.
  List<Validator<T>> get validators => List.unmodifiable(_validators);

  @override
  ValidationResult validate(T value) {
    return _validators.fold(
      const ValidationResult.valid(),
      (accumulated, validator) => accumulated.merge(validator.validate(value)),
    );
  }
}
