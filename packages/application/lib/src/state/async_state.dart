import 'package:platform_core/exceptions/app_exception.dart';

/// A sealed discriminated union modelling the three states of an async
/// operation: loading, success, and error.
///
/// Use the named factories [AsyncState.loading], [AsyncState.success], and
/// [AsyncState.error] to construct instances, then exhaustively pattern-match
/// with [when] or use the convenience guards [isLoading], [isSuccess],
/// [isError].
///
/// Example:
/// ```dart
/// AsyncState<List<User>> state = const AsyncState.loading();
/// // … later …
/// state = AsyncState.success(users);
///
/// state.when(
///   loading: () => showSpinner(),
///   success: (data) => buildList(data),
///   error: (e) => showError(e.message),
/// );
/// ```
sealed class AsyncState<T> {
  const AsyncState();

  /// Constructs the loading variant.
  const factory AsyncState.loading() = LoadingState<T>;

  /// Constructs the success variant wrapping [data].
  const factory AsyncState.success(T data) = SuccessState<T>;

  /// Constructs the error variant wrapping [error].
  const factory AsyncState.error(AppException error) = ErrorState<T>;

  // ── Predicates ─────────────────────────────────────────────────────────────

  bool get isLoading => this is LoadingState<T>;
  bool get isSuccess => this is SuccessState<T>;
  bool get isError => this is ErrorState<T>;

  // ── Accessors ───────────────────────────────────────────────────────────────

  /// Returns the success data if this is [SuccessState], otherwise `null`.
  T? get dataOrNull => switch (this) {
        SuccessState(:final data) => data,
        _ => null,
      };

  /// Returns the exception if this is [ErrorState], otherwise `null`.
  AppException? get errorOrNull => switch (this) {
        ErrorState(:final error) => error,
        _ => null,
      };

  // ── Pattern matching ────────────────────────────────────────────────────────

  /// Exhaustively maps each variant to a value of [R].
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(AppException error) error,
  }) =>
      switch (this) {
        LoadingState<T>() => loading(),
        SuccessState(:final data) => success(data),
        ErrorState(error: final e) => error(e),
      };
}

/// The loading variant of [AsyncState].
final class LoadingState<T> extends AsyncState<T> {
  const LoadingState();

  @override
  String toString() => 'AsyncState<$T>.loading()';
}

/// The success variant of [AsyncState], carrying [data].
final class SuccessState<T> extends AsyncState<T> {
  const SuccessState(this.data);

  /// The successfully produced value.
  final T data;

  @override
  bool operator ==(Object other) =>
      other is SuccessState<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'AsyncState<$T>.success($data)';
}

/// The error variant of [AsyncState], carrying an [AppException].
final class ErrorState<T> extends AsyncState<T> {
  const ErrorState(this.error);

  /// The exception that caused the failure.
  final AppException error;

  @override
  bool operator ==(Object other) =>
      other is ErrorState<T> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'AsyncState<$T>.error($error)';
}
