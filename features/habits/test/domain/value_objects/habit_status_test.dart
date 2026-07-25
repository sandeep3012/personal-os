import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitStatus transitions', () {
    test('active can transition to archived only', () {
      expect(HabitStatus.active.allowedNextStatuses, {HabitStatus.archived});
    });

    test('archived is terminal — no allowed next statuses', () {
      expect(HabitStatus.archived.allowedNextStatuses, isEmpty);
    });

    test('canTransitionTo reflects allowedNextStatuses', () {
      expect(HabitStatus.active.canTransitionTo(HabitStatus.archived), isTrue);
      expect(HabitStatus.active.canTransitionTo(HabitStatus.active), isFalse);
      expect(
        HabitStatus.archived.canTransitionTo(HabitStatus.active),
        isFalse,
      );
    });
  });
}
