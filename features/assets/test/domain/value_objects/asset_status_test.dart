import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetStatusTransitions', () {
    test('active can transition to disposed', () {
      expect(AssetStatus.active.canTransitionTo(AssetStatus.disposed), isTrue);
    });

    test('active can transition to archived', () {
      expect(AssetStatus.active.canTransitionTo(AssetStatus.archived), isTrue);
    });

    test('disposed cannot transition anywhere', () {
      expect(AssetStatus.disposed.allowedNextStatuses, isEmpty);
      expect(AssetStatus.disposed.canTransitionTo(AssetStatus.active), isFalse);
    });

    test('archived cannot transition anywhere', () {
      expect(AssetStatus.archived.allowedNextStatuses, isEmpty);
      expect(AssetStatus.archived.canTransitionTo(AssetStatus.active), isFalse);
    });

    test('active cannot transition to itself', () {
      expect(AssetStatus.active.canTransitionTo(AssetStatus.active), isFalse);
    });
  });
}
