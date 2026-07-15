import 'package:feature_sample/src/application/sample_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SampleService', () {
    late SampleService service;

    setUp(() => service = SampleService());

    test('isLoaded is false initially', () {
      expect(service.isLoaded, isFalse);
    });

    test('status returns initializing message before load', () {
      expect(service.status, isNot(contains('Successfully')));
    });

    test('markLoaded sets isLoaded to true', () {
      service.markLoaded();
      expect(service.isLoaded, isTrue);
    });

    test('status returns success message after markLoaded', () {
      service.markLoaded();
      expect(service.status, contains('Sample Feature Loaded Successfully'));
    });

    test('markLoaded is idempotent', () {
      service.markLoaded();
      service.markLoaded();
      expect(service.isLoaded, isTrue);
      expect(service.status, contains('Successfully'));
    });
  });
}
