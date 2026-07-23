import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalStatus transitions', () {
    test('active can transition to completed or archived', () {
      expect(GoalStatus.active.allowedNextStatuses, {
        GoalStatus.completed,
        GoalStatus.archived,
      });
    });

    test('completed can transition to archived only', () {
      expect(GoalStatus.completed.allowedNextStatuses, {GoalStatus.archived});
    });

    test('archived is terminal — no allowed next statuses', () {
      expect(GoalStatus.archived.allowedNextStatuses, isEmpty);
    });

    test('canTransitionTo reflects allowedNextStatuses', () {
      expect(GoalStatus.active.canTransitionTo(GoalStatus.completed), isTrue);
      expect(GoalStatus.active.canTransitionTo(GoalStatus.archived), isTrue);
      expect(GoalStatus.active.canTransitionTo(GoalStatus.active), isFalse);
      expect(
        GoalStatus.completed.canTransitionTo(GoalStatus.active),
        isFalse,
      );
      expect(
        GoalStatus.archived.canTransitionTo(GoalStatus.active),
        isFalse,
      );
    });
  });
}
