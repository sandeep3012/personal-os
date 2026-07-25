import 'package:application/application.dart';
import 'package:feature_assets/src/application/use_cases/get_assets_use_case.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter/foundation.dart';

/// The Home Dashboard's Assets summary data — a presentation-layer
/// computation over [GetAssetsUseCase]'s result, not a domain type.
/// Mirrors `NotesDashboardSummary`.
final class AssetsDashboardSummary {
  const AssetsDashboardSummary({
    required this.activeCount,
    required this.totalValue,
  });

  /// Count of assets with [AssetStatus.active].
  final int activeCount;

  /// Sum of [Asset.value] across all active assets.
  final double totalValue;
}

/// Drives the Assets [ModuleCard] on [HomeDashboardPage] — mirrors
/// `NotesHomeViewModel` exactly: a small, isolated aggregator ViewModel
/// distinct from [AssetsViewModel] (the full list page).
///
/// No new summary use case is introduced — the counts are computed
/// presentation-side from [GetAssetsUseCase]'s result, mirroring how
/// `NotesDashboardSummary` is assembled.
final class AssetsHomeViewModel extends ChangeNotifier {
  AssetsHomeViewModel({
    required GetAssetsUseCase getAssetsUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getAssetsUseCase = getAssetsUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;
  String get workspaceId => _workspaceContext.workspaceId;

  final GetAssetsUseCase _getAssetsUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<AssetsDashboardSummary> _state = const AsyncState.loading();

  /// The current load state: loading, success (with the summary), or error.
  AsyncState<AssetsDashboardSummary> get state => _state;

  var _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  Future<void> load() => _fetch(isRefresh: false);
  Future<void> refresh() => _fetch(isRefresh: true);

  Future<void> _fetch({required bool isRefresh}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _state = const AsyncState.loading();
    }
    notifyListeners();

    final result = await _getAssetsUseCase.execute(
      GetAssetsInput(workspaceId: workspaceId),
    );

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final assets = result.valueOrNull!;
    final active = assets.where((a) => a.status == AssetStatus.active);
    final activeCount = active.length;
    final totalValue = active.fold<double>(0, (sum, a) => sum + a.value);

    _state = AsyncState.success(AssetsDashboardSummary(
      activeCount: activeCount,
      totalValue: totalValue,
    ));
    _isRefreshing = false;
    notifyListeners();
  }
}
