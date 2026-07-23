import 'package:feature_habits/src/domain/value_objects/habit_status.dart';

/// Filter and pagination parameters for [SearchHabitsUseCase] (DOC-032 §7.1).
///
/// All filter fields are optional — absent fields impose no constraint.
/// Results are paginated via [pageIndex] / [pageSize]. Mirrors Finance's
/// `TransactionQuery` shape.
final class HabitQuery {
  const HabitQuery({
    required this.workspaceId,
    this.status,
    this.nameContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final HabitStatus? status;
  final String? nameContains;
  final int pageIndex;
  final int pageSize;
}
