import 'package:feature_tasks/src/domain/entities/task.dart';

/// A single page of [Task] results from [SearchTasksUseCase]. Mirrors
/// Finance's `TransactionPage`.
final class TaskPage {
  const TaskPage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<Task> items;
  final int totalCount;
  final bool hasNextPage;
}
