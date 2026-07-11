import 'package:platform_core/result/result.dart';

/// Base interface for asynchronous use cases that accept a parameter.
///
/// [Input] is the parameter type. [Output] is the success type wrapped in
/// [Result]. Use [NoParamsUseCase] for operations that need no input.
///
/// Example:
/// ```dart
/// final class LoadUserUseCase implements AsyncUseCase<String, User> {
///   const LoadUserUseCase(this._repo);
///   final UserRepository _repo;
///
///   @override
///   Future<Result<User>> execute(String userId) => _repo.findById(userId);
/// }
/// ```
abstract interface class AsyncUseCase<Input, Output> {
  /// Executes the use case with [input] and returns a [Result] asynchronously.
  Future<Result<Output>> execute(Input input);
}
