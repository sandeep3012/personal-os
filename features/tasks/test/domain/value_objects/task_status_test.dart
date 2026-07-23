import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskStatus transitions', () {
    test('todo can transition to in_progress, completed, or archived', () {
      expect(TaskStatus.todo.allowedNextStatuses, {
        TaskStatus.inProgress,
        TaskStatus.completed,
        TaskStatus.archived,
      });
    });

    test('in_progress can transition to completed or archived', () {
      expect(TaskStatus.inProgress.allowedNextStatuses, {
        TaskStatus.completed,
        TaskStatus.archived,
      });
    });

    test('completed can transition to archived only', () {
      expect(TaskStatus.completed.allowedNextStatuses, {TaskStatus.archived});
    });

    test('archived is terminal — no allowed next statuses', () {
      expect(TaskStatus.archived.allowedNextStatuses, isEmpty);
    });

    test('canTransitionTo reflects allowedNextStatuses', () {
      expect(TaskStatus.todo.canTransitionTo(TaskStatus.completed), isTrue);
      expect(TaskStatus.todo.canTransitionTo(TaskStatus.todo), isFalse);
      expect(
        TaskStatus.completed.canTransitionTo(TaskStatus.inProgress),
        isFalse,
      );
      expect(
        TaskStatus.archived.canTransitionTo(TaskStatus.todo),
        isFalse,
      );
    });
  });
}
