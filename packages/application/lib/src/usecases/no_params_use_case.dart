import 'package:platform_core/result/result.dart';

/// Base interface for asynchronous use cases that require no input parameter.
///
/// [Output] is the success type wrapped in [Result].
///
/// Example:
/// ```dart
/// final class GetCurrentUserUseCase implements NoParamsUseCase<User> {
///   const GetCurrentUserUseCase(this._session);
///   final SessionService _session;
///
///   @override
///   Future<Result<User>> execute() => _session.currentUser();
/// }
/// ```
abstract interface class NoParamsUseCase<Output> {
  /// Executes the use case and returns a [Result] asynchronously.
  Future<Result<Output>> execute();
}
