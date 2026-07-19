import 'package:application/application.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_category_summary_use_case.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:flutter/foundation.dart';

/// A category's total spend for the current period, for display only.
///
/// Not a domain type — a presentation-layer projection of one entry from
/// [GetCategorySummaryUseCase]'s `Map<CategoryId, Money>` result.
final class CategorySummaryItem {
  const CategorySummaryItem({required this.categoryId, required this.total});

  final CategoryId categoryId;
  final Money total;
}

/// Drives [CategoriesPage]: shows expense totals grouped by category for the
/// current calendar month.
///
/// DOC-031 §5.1 is explicit that Finance never performs category CRUD —
/// categories are opaque references owned by the (not-yet-built) platform
/// Classification Service. Consequently there is no "list categories",
/// "create category", "update category", or "delete category" use case in
/// the Sprint 8A catalog, and this ViewModel does not invent one. It only
/// derives a category list from [GetCategorySummaryUseCase] — the
/// categories that actually appear on existing expense transactions, with
/// their totals — and offers client-side text search over that already-
/// fetched result (no repeated use-case calls per keystroke; search is pure
/// presentation-layer filtering, not a new business capability).
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004).
final class CategoriesViewModel extends ChangeNotifier {
  CategoriesViewModel({
    required GetCategorySummaryUseCase getCategorySummaryUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getCategorySummaryUseCase = getCategorySummaryUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetCategorySummaryUseCase _getCategorySummaryUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<CategorySummaryItem>> _rawState = const AsyncState.loading();

  var _searchQuery = '';

  /// The current search filter over category ids. Empty means "no filter".
  String get searchQuery => _searchQuery;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// The current load state, with [searchQuery] applied to a successful
  /// result. Loading/error states pass through unfiltered — there is
  /// nothing to filter yet.
  AsyncState<List<CategorySummaryItem>> get state {
    final raw = _rawState.dataOrNull;
    if (raw == null) return _rawState;
    if (_searchQuery.isEmpty) return _rawState;
    final query = _searchQuery.toLowerCase();
    final filtered =
        raw.where((item) => item.categoryId.value.toLowerCase().contains(query)).toList();
    return AsyncState.success(filtered);
  }

  /// Updates the search filter. Purely client-side — does not re-invoke
  /// [GetCategorySummaryUseCase].
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Loads category summaries for the first time (or after an error),
  /// showing the full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads while keeping the current list visible ([isRefreshing] becomes
  /// `true` instead of resetting [state] to loading).
  Future<void> refresh() => _fetch(isRefresh: true);

  Future<void> _fetch({required bool isRefresh}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _rawState = const AsyncState.loading();
    }
    notifyListeners();

    final period = FinancePeriod.fromDateTime(DateTime.now());
    final result = await _getCategorySummaryUseCase.execute(
      GetCategorySummaryInput(workspaceId: workspaceId, period: period),
    );

    if (result.isFailure) {
      _rawState = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final items = [
      for (final entry in result.valueOrNull!.entries)
        CategorySummaryItem(categoryId: entry.key, total: entry.value),
    ];

    _rawState = AsyncState.success(items);
    _isRefreshing = false;
    notifyListeners();
  }
}
