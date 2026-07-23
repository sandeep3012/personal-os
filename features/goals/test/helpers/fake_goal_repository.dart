import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_page.dart';
import 'package:feature_goals/src/domain/value_objects/goal_query.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [IGoalRepository] for use-case unit tests. Mirrors Finance's
/// `FakeAccountRepository`.
final class FakeGoalRepository implements IGoalRepository {
  final List<Goal> _store = [];

  List<Goal> get store => List.unmodifiable(_store);

  void seed(List<Goal> goals) {
    _store.clear();
    _store.addAll(goals);
  }

  @override
  FutureResult<Goal?> findById(GoalId id, {required String workspaceId}) async =>
      Result.success(_store.where((t) => t.id == id).firstOrNull);

  @override
  FutureResult<List<Goal>> findAll({required String workspaceId}) async =>
      Result.success(List.unmodifiable(_store));

  @override
  FutureResult<List<Goal>> findByStatus(
    GoalStatus status, {
    required String workspaceId,
  }) async =>
      Result.success(
        List.unmodifiable(_store.where((t) => t.status == status).toList()),
      );

  @override
  FutureResult<GoalPage> search(GoalQuery query) async {
    var filtered = _store.where((t) => t.workspaceId == query.workspaceId);
    if (query.status != null) {
      filtered = filtered.where((t) => t.status == query.status);
    }
    if (query.nameContains != null && query.nameContains!.isNotEmpty) {
      filtered = filtered.where(
        (t) => t.name.toLowerCase().contains(query.nameContains!.toLowerCase()),
      );
    }
    final all = filtered.toList();
    final start = query.pageIndex * query.pageSize;
    final end = (start + query.pageSize).clamp(0, all.length);
    final items = start >= all.length ? <Goal>[] : all.sublist(start, end);

    return Result.success(GoalPage(
      items: items,
      totalCount: all.length,
      hasNextPage: end < all.length,
    ));
  }

  @override
  FutureResult<void> save(Goal goal) async {
    _store.removeWhere((t) => t.id == goal.id);
    _store.add(goal);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(GoalId id, {required String workspaceId}) async {
    _store.removeWhere((t) => t.id == id);
    return const Result.success(null);
  }
}
