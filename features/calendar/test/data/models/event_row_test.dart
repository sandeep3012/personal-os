import 'package:feature_calendar/src/data/models/event_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventRow toMap/fromMap round-trip', () {
    test('round-trips all fields including nullable deletedAt', () {
      final row = EventRow(
        eventId: 'event-1',
        workspaceId: 'ws-1',
        title: 'Standup',
        description: 'Daily sync',
        location: 'Room A',
        startTime: DateTime(2026, 1, 1, 9),
        endTime: DateTime(2026, 1, 1, 9, 30),
        status: 'active',
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 3, 8),
        deletedAt: null,
      );

      final restored = EventRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips a soft-deleted row', () {
      final row = EventRow(
        eventId: 'event-2',
        workspaceId: 'ws-1',
        title: 'Archived event',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        status: 'archived',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 6),
        deletedAt: DateTime(2026, 1, 7),
      );

      final restored = EventRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips minimal fields (no description/location)', () {
      final row = EventRow(
        eventId: 'event-3',
        workspaceId: 'ws-1',
        title: 'Minimal',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = EventRow.fromMap(row.toMap());

      expect(restored, row);
      expect(restored.description, '');
      expect(restored.location, '');
      expect(restored.deletedAt, isNull);
    });

    test('decodes a null description/location column back to empty string', () {
      final restored = EventRow.fromMap({
        'event_id': 'event-5',
        'workspace_id': 'ws-1',
        'title': 'No extras',
        'description': null,
        'location': null,
        'start_time': DateTime(2026, 1, 1).toIso8601String(),
        'end_time': DateTime(2026, 1, 1, 1).toIso8601String(),
        'status': 'active',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime(2026, 1, 1).toIso8601String(),
        'deleted_at': null,
      });

      expect(restored.description, '');
      expect(restored.location, '');
    });
  });
}
