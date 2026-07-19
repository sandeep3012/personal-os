import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/app/onboarding/onboarding_status_store.dart';

File _tempFile() => File(
      '${Directory.systemTemp.createTempSync('onboarding_status_store_test_').path}'
      '/onboarding_status.json',
    );

void main() {
  group('OnboardingStatusStore', () {
    test('hasCompletedOnboarding is false when the file does not exist yet',
        () async {
      final store = OnboardingStatusStore(_tempFile());

      expect(await store.hasCompletedOnboarding(), isFalse);
    });

    test('markCompleted persists completion across a fresh store instance',
        () async {
      final file = _tempFile();
      final store = OnboardingStatusStore(file);

      await store.markCompleted();

      final reloaded = OnboardingStatusStore(file);
      expect(await reloaded.hasCompletedOnboarding(), isTrue);
    });
  });
}
