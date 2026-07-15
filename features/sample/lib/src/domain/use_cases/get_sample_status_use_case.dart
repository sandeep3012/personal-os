import 'package:application/application.dart';
import 'package:feature_sample/src/application/sample_service.dart';
import 'package:platform_core/result/result.dart';

/// Returns the current load status of the Sample feature.
///
/// Implements [NoParamsUseCase] to exercise the use-case framework
/// contract from [packages/application].
///
/// Example:
/// ```dart
/// final useCase = GetSampleStatusUseCase(sampleService);
/// final result = await useCase.execute();
/// result.when(
///   success: (status) => print(status),
///   failure: (e) => print(e.message),
/// );
/// ```
final class GetSampleStatusUseCase implements NoParamsUseCase<String> {
  const GetSampleStatusUseCase(this._service);

  final SampleService _service;

  @override
  Future<Result<String>> execute() async =>
      Result.success(_service.status);
}
