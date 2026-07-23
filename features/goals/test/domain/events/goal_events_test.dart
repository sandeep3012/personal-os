import 'package:feature_goals/src/domain/events/goal_archived_event.dart';
import 'package:feature_goals/src/domain/events/goal_completed_event.dart';
import 'package:feature_goals/src/domain/events/goal_created_event.dart';
import 'package:feature_goals/src/domain/events/goal_deleted_event.dart';
import 'package:feature_goals/src/domain/events/goal_updated_event.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

void main() {
  group('GoalCreatedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 1);
      final event = GoalCreatedEvent(
        goalId: const GoalId('goal-1'),
        workspaceId: _ws,
        name: 'Buy groceries',
        status: GoalStatus.active,
        timestamp: timestamp,
      );

      expect(event.goalId, const GoalId('goal-1'));
      expect(event.workspaceId, _ws);
      expect(event.name, 'Buy groceries');
      expect(event.status, GoalStatus.active);
      expect(event.timestamp, timestamp);
    });
  });

  group('GoalUpdatedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 2);
      final event = GoalUpdatedEvent(
        goalId: const GoalId('goal-1'),
        workspaceId: _ws,
        name: 'Renamed',
        status: GoalStatus.active,
        timestamp: timestamp,
      );

      expect(event.name, 'Renamed');
      expect(event.status, GoalStatus.active);
      expect(event.timestamp, timestamp);
    });
  });

  group('GoalCompletedEvent', () {
    test('holds all constructor fields', () {
      final completedAt = DateTime(2026, 1, 3);
      final timestamp = DateTime(2026, 1, 3);
      final event = GoalCompletedEvent(
        goalId: const GoalId('goal-1'),
        workspaceId: _ws,
        completedAt: completedAt,
        timestamp: timestamp,
      );

      expect(event.completedAt, completedAt);
      expect(event.timestamp, timestamp);
    });
  });

  group('GoalArchivedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 4);
      final event = GoalArchivedEvent(
        goalId: const GoalId('goal-1'),
        workspaceId: _ws,
        timestamp: timestamp,
      );

      expect(event.goalId, const GoalId('goal-1'));
      expect(event.workspaceId, _ws);
      expect(event.timestamp, timestamp);
    });
  });

  group('GoalDeletedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 5);
      final event = GoalDeletedEvent(
        goalId: const GoalId('goal-1'),
        workspaceId: _ws,
        timestamp: timestamp,
      );

      expect(event.goalId, const GoalId('goal-1'));
      expect(event.workspaceId, _ws);
      expect(event.timestamp, timestamp);
    });
  });
}
