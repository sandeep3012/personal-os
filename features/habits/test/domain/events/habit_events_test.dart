import 'package:feature_habits/src/domain/events/habit_archived_event.dart';
import 'package:feature_habits/src/domain/events/habit_completed_event.dart';
import 'package:feature_habits/src/domain/events/habit_created_event.dart';
import 'package:feature_habits/src/domain/events/habit_deleted_event.dart';
import 'package:feature_habits/src/domain/events/habit_updated_event.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

void main() {
  group('HabitCreatedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 1);
      final event = HabitCreatedEvent(
        habitId: const HabitId('habit-1'),
        workspaceId: _ws,
        name: 'Buy groceries',
        status: HabitStatus.active,
        timestamp: timestamp,
      );

      expect(event.habitId, const HabitId('habit-1'));
      expect(event.workspaceId, _ws);
      expect(event.name, 'Buy groceries');
      expect(event.status, HabitStatus.active);
      expect(event.timestamp, timestamp);
    });
  });

  group('HabitUpdatedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 2);
      final event = HabitUpdatedEvent(
        habitId: const HabitId('habit-1'),
        workspaceId: _ws,
        name: 'Renamed',
        status: HabitStatus.active,
        timestamp: timestamp,
      );

      expect(event.name, 'Renamed');
      expect(event.status, HabitStatus.active);
      expect(event.timestamp, timestamp);
    });
  });

  group('HabitCompletedEvent', () {
    test('holds all constructor fields', () {
      final completedAt = DateTime(2026, 1, 3);
      final timestamp = DateTime(2026, 1, 3);
      final event = HabitCompletedEvent(
        habitId: const HabitId('habit-1'),
        workspaceId: _ws,
        completedAt: completedAt,
        timestamp: timestamp,
      );

      expect(event.completedAt, completedAt);
      expect(event.timestamp, timestamp);
    });
  });

  group('HabitArchivedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 4);
      final event = HabitArchivedEvent(
        habitId: const HabitId('habit-1'),
        workspaceId: _ws,
        timestamp: timestamp,
      );

      expect(event.habitId, const HabitId('habit-1'));
      expect(event.workspaceId, _ws);
      expect(event.timestamp, timestamp);
    });
  });

  group('HabitDeletedEvent', () {
    test('holds all constructor fields', () {
      final timestamp = DateTime(2026, 1, 5);
      final event = HabitDeletedEvent(
        habitId: const HabitId('habit-1'),
        workspaceId: _ws,
        timestamp: timestamp,
      );

      expect(event.habitId, const HabitId('habit-1'));
      expect(event.workspaceId, _ws);
      expect(event.timestamp, timestamp);
    });
  });
}
