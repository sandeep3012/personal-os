import 'package:feature_goals/src/domain/value_objects/goal_status.dart';

/// Filter and pagination parameters for [SearchGoalsUseCase] (DOC-032 §7.1).
///
/// All filter fields are optional — absent fields impose no constraint.
/// Results are paginated via [pageIndex] / [pageSize]. Mirrors Finance's
/// `TransactionQuery` shape.
final class GoalQuery {
  const GoalQuery({
    required this.workspaceId,
    this.status,
    this.nameContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final GoalStatus? status;
  final String? nameContains;
  final int pageIndex;
  final int pageSize;
}
