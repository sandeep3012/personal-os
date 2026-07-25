import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:feature_habits/src/domain/value_objects/habit_page.dart';
import 'package:feature_habits/src/domain/value_objects/habit_query.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [IHabitRepository] for use-case unit tests. Mirrors Finance's
/// `FakeAccountRepository`.
final class FakeHabitRepository implements IHabitRepository {
  final List<Habit> _store = [];

  List<Habit> get store => List.unmodifiable(_store);

  void seed(List<Habit> habits) {
    _store.clear();
    _store.addAll(habits);
  }

  @override
  FutureResult<Habit?> findById(HabitId id, {required String workspaceId}) async =>
      Result.success(_store.where((t) => t.id == id).firstOrNull);

  @override
  FutureResult<List<Habit>> findAll({required String workspaceId}) async =>
      Result.success(List.unmodifiable(_store));

  @override
  FutureResult<List<Habit>> findByStatus(
    HabitStatus status, {
    required String workspaceId,
  }) async =>
      Result.success(
        List.unmodifiable(_store.where((t) => t.status == status).toList()),
      );

  @override
  FutureResult<HabitPage> search(HabitQuery query) async {
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
    final items = start >= all.length ? <Habit>[] : all.sublist(start, end);

    return Result.success(HabitPage(
      items: items,
      totalCount: all.length,
      hasNextPage: end < all.length,
    ));
  }

  @override
  FutureResult<void> save(Habit habit) async {
    _store.removeWhere((t) => t.id == habit.id);
    _store.add(habit);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(HabitId id, {required String workspaceId}) async {
    _store.removeWhere((t) => t.id == id);
    return const Result.success(null);
  }
}
