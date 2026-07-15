import 'package:feature_sample/src/application/sample_service.dart';
import 'package:feature_sample/src/domain/use_cases/get_sample_status_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GetSampleStatusUseCase', () {
    late SampleService service;
    late GetSampleStatusUseCase useCase;

    setUp(() {
      service = SampleService();
      useCase = GetSampleStatusUseCase(service);
    });

    test('returns Success with initializing status before load', () async {
      final result = await useCase.execute();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNot(contains('Successfully')));
    });

    test('returns Success with loaded status after markLoaded', () async {
      service.markLoaded();
      final result = await useCase.execute();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, contains('Sample Feature Loaded Successfully'));
    });

    test('never returns Failure for this trivial service', () async {
      final result = await useCase.execute();
      expect(result.isFailure, isFalse);
    });
  });
}
