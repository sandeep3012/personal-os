import 'package:feature_tasks/src/data/models/task_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskRow toMap/fromMap round-trip', () {
    test('round-trips all fields including nullable ones', () {
      final row = TaskRow(
        taskId: 'task-1',
        workspaceId: 'ws-1',
        title: 'Buy groceries',
        status: 'inProgress',
        description: 'Milk, eggs, bread',
        dueDate: DateTime(2026, 3, 1),
        completedAt: null,
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 2, 8),
        deletedAt: null,
      );

      final restored = TaskRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips a fully nullable-fields-populated row', () {
      final row = TaskRow(
        taskId: 'task-2',
        workspaceId: 'ws-1',
        title: 'Archived task',
        status: 'archived',
        completedAt: DateTime(2026, 1, 5),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 6),
        deletedAt: DateTime(2026, 1, 7),
      );

      final restored = TaskRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips minimal fields (no description/dueDate/completedAt)', () {
      final row = TaskRow(
        taskId: 'task-3',
        workspaceId: 'ws-1',
        title: 'Minimal',
        status: 'todo',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = TaskRow.fromMap(row.toMap());

      expect(restored, row);
      expect(restored.description, isNull);
      expect(restored.dueDate, isNull);
      expect(restored.completedAt, isNull);
      expect(restored.deletedAt, isNull);
    });
  });
}
