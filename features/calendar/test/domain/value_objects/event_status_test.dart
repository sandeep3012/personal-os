import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventStatusTransitions', () {
    test('active can transition to archived', () {
      expect(EventStatus.active.canTransitionTo(EventStatus.archived), isTrue);
    });

    test('archived cannot transition anywhere', () {
      expect(EventStatus.archived.allowedNextStatuses, isEmpty);
      expect(EventStatus.archived.canTransitionTo(EventStatus.active), isFalse);
    });

    test('active cannot transition to itself', () {
      expect(EventStatus.active.canTransitionTo(EventStatus.active), isFalse);
    });
  });
}
