import 'package:feature_tasks/src/domain/exceptions/tasks_exception.dart';
import 'package:feature_tasks/src/domain/value_objects/task_due_date.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';

/// A Task aggregate root — a single, standalone unit of personal work
/// (DOC-032 §4). There is no owning Project/List/Board entity; grouping, if
/// ever introduced, happens through the platform Entity Linking Service, not
/// through a field on this entity.
///
/// Business invariants enforced here:
/// - [title] must not be empty and must not exceed 200 characters (DOC-032 §5.3).
/// - Status transitions are only permitted per the approved transition table
///   (DOC-032 §10 Business Rule 3, §11) — enforced by [transitionTo], not by
///   direct field mutation (this class has no public status setter).
final class Task {
  Task({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.dueDate,
    this.completedAt,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const TasksException(message: 'Task title must not be empty');
    }
    if (title.length > 200) {
      throw const TasksException(
        message: 'Task title must not exceed 200 characters',
      );
    }
  }

  final TaskId id;
  final String workspaceId;
  final String title;
  final TaskStatus status;

  /// Optional free text (DOC-032 §5.1). Max 1000 characters (§5.3) — enforced
  /// at the use-case validation layer, mirroring how Finance validates
  /// `Transaction.note` at the use-case input layer rather than in the
  /// entity constructor.
  final String? description;

  /// Optional due date (DOC-032 §5.1, §6.2). No range restriction.
  final TaskDueDate? dueDate;

  /// Set exactly when [status] transitions to [TaskStatus.completed]
  /// (DOC-032 §10 Business Rule 4). Retained (not cleared) if a completed
  /// Task is later archived; remains `null` if a Task is archived without
  /// ever having completed.
  final DateTime? completedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this task with the supplied fields replaced.
  ///
  /// Does not change [status] — use [transitionTo] for status changes, which
  /// enforces the approved transition table (DOC-032 §11) and the
  /// `completedAt` rule (DOC-032 §10 Business Rule 4). This mirrors
  /// `UpdateAccountUseCase` rejecting currency as an updatable input: some
  /// fields are deliberately not reachable through the generic "update" path.
  Task copyWith({
    String? title,
    String? description,
    TaskDueDate? dueDate,
    DateTime? updatedAt,
  }) =>
      Task(
        id: id,
        workspaceId: workspaceId,
        title: title ?? this.title,
        status: status,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        completedAt: completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy of this task transitioned to [next].
  ///
  /// Throws [TasksException] if [next] is not reachable from [status] per
  /// the approved transition table (DOC-032 §11):
  ///
  /// ```
  /// todo        -> in_progress, completed, archived
  /// in_progress -> completed, archived
  /// completed   -> archived
  /// archived    -> (none — terminal)
  /// ```
  ///
  /// Sets [completedAt] to [now] when transitioning into
  /// [TaskStatus.completed]; otherwise carries the existing [completedAt]
  /// forward unchanged (DOC-032 §10 Business Rule 4) — archiving a completed
  /// task does not erase its completion record, and archiving directly from
  /// `todo`/`in_progress` never sets one.
  Task transitionTo(TaskStatus next, {required DateTime now}) {
    if (!status.canTransitionTo(next)) {
      throw TasksException(
        message:
            'Cannot transition Task from ${status.name} to ${next.name}',
      );
    }
    return Task(
      id: id,
      workspaceId: workspaceId,
      title: title,
      status: next,
      description: description,
      dueDate: dueDate,
      completedAt: next == TaskStatus.completed ? now : completedAt,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task(id: $id, title: $title, status: ${status.name})';
}
