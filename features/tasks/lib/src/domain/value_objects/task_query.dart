import 'package:feature_tasks/src/domain/value_objects/task_status.dart';

/// Filter and pagination parameters for [SearchTasksUseCase] (DOC-032 §7.1).
///
/// All filter fields are optional — absent fields impose no constraint.
/// Results are paginated via [pageIndex] / [pageSize]. Mirrors Finance's
/// `TransactionQuery` shape.
final class TaskQuery {
  const TaskQuery({
    required this.workspaceId,
    this.status,
    this.titleContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final TaskStatus? status;
  final String? titleContains;
  final int pageIndex;
  final int pageSize;
}
