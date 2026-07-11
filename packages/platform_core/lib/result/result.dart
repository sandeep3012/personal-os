import 'package:platform_core/exceptions/app_exception.dart';

/// A discriminated union representing either a successful value [T] or a
/// structured [AppException].
///
/// Use [Result.success] / [Result.failure] factories to create instances.
/// Pattern-match with [when], or use the functional helpers [map], [flatMap],
/// [onSuccess], and [onFailure].
///
/// Example:
/// ```dart
/// Future<Result<User>> fetchUser(String id) async {
///   try {
///     final user = await api.getUser(id);
///     return Result.success(user);
///   } on Exception catch (e) {
///     return Result.failure(UnknownException(message: e.toString()));
///   }
/// }
///
/// final result = await fetchUser('123');
/// result.when(
///   success: (user) => print(user.name),
///   failure: (e) => print(e.message),
/// );
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful result wrapping [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result wrapping [exception].
  const factory Result.failure(AppException exception) = Failure<T>;

  // ── Predicates ──────────────────────────────────────────────────────────

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  // ── Accessors ────────────────────────────────────────────────────────────

  /// Returns the value if this is [Success], otherwise `null`.
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  /// Returns the exception if this is [Failure], otherwise `null`.
  AppException? get exceptionOrNull => switch (this) {
        Success() => null,
        Failure(:final exception) => exception,
      };

  // ── Pattern matching ─────────────────────────────────────────────────────

  /// Exhaustively handles both cases, returning [R].
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  }) =>
      switch (this) {
        Success(:final value) => success(value),
        Failure(:final exception) => failure(exception),
      };

  // ── Transformations ──────────────────────────────────────────────────────

  /// Transforms the contained value if [Success]; passes [Failure] through
  /// unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success(:final value) => Success(transform(value)),
        Failure(:final exception) => Failure(exception),
      };

  /// Chains a fallible computation if [Success]; passes [Failure] through
  /// unchanged.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Success(:final value) => transform(value),
        Failure(:final exception) => Failure(exception),
      };

  // ── Side-effect helpers ──────────────────────────────────────────────────

  /// Invokes [action] with the value if [Success]; returns `this` unchanged.
  Result<T> onSuccess(void Function(T value) action) {
    if (this case Success(:final value)) action(value);
    return this;
  }

  /// Invokes [action] with the exception if [Failure]; returns `this`
  /// unchanged.
  Result<T> onFailure(void Function(AppException exception) action) {
    if (this case Failure(:final exception)) action(exception);
    return this;
  }
}

/// The successful variant of [Result].
final class Success<T> extends Result<T> {
  const Success(this.value);

  /// The wrapped success value.
  final T value;

  @override
  bool operator ==(Object other) =>
      other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// The failure variant of [Result].
final class Failure<T> extends Result<T> {
  const Failure(this.exception);

  /// The structured exception describing why the operation failed.
  final AppException exception;

  @override
  bool operator ==(Object other) =>
      other is Failure<T> && other.exception == exception;

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure($exception)';
}
