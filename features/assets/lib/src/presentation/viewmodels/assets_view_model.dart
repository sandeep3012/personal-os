import 'package:application/application.dart';
import 'package:feature_assets/src/application/use_cases/archive_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/create_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/delete_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/dispose_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/get_assets_use_case.dart';
import 'package:feature_assets/src/application/use_cases/update_asset_use_case.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// Drives [AssetsPage]: loads all assets and exposes create/update/
/// dispose/archive/delete operations.
///
/// Depends only on use cases — never on [IAssetRepository] directly. All
/// business rules (name/category validation, value non-negativity,
/// status-transition legality, etc.) are enforced by the use cases and the
/// [Asset] entity beneath them; this ViewModel neither duplicates nor
/// bypasses them — it only orchestrates calls and surfaces whatever
/// [Result] they return. Mirrors `NotesViewModel` exactly.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) —
/// this ViewModel never invents or hardcodes a workspace identifier, and
/// reloads automatically when [WorkspaceContext] reports a switch.
final class AssetsViewModel extends ChangeNotifier {
  AssetsViewModel({
    required GetAssetsUseCase getAssetsUseCase,
    required CreateAssetUseCase createAssetUseCase,
    required UpdateAssetUseCase updateAssetUseCase,
    required ArchiveAssetUseCase archiveAssetUseCase,
    required DisposeAssetUseCase disposeAssetUseCase,
    required DeleteAssetUseCase deleteAssetUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getAssetsUseCase = getAssetsUseCase,
        _createAssetUseCase = createAssetUseCase,
        _updateAssetUseCase = updateAssetUseCase,
        _archiveAssetUseCase = archiveAssetUseCase,
        _disposeAssetUseCase = disposeAssetUseCase,
        _deleteAssetUseCase = deleteAssetUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetAssetsUseCase _getAssetsUseCase;
  final CreateAssetUseCase _createAssetUseCase;
  final UpdateAssetUseCase _updateAssetUseCase;
  final ArchiveAssetUseCase _archiveAssetUseCase;
  final DisposeAssetUseCase _disposeAssetUseCase;
  final DeleteAssetUseCase _deleteAssetUseCase;

  /// Reloads the asset list for the newly-active workspace — presentation
  /// plumbing only, mirrors `NotesViewModel._handleWorkspaceChanged`.
  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<Asset>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with assets), or error.
  AsyncState<List<Asset>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// Loads assets for the first time (or after an error), showing the
  /// full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads assets while keeping the current list visible ([isRefreshing]
  /// becomes `true` instead of resetting [state] to loading).
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

    _state = AsyncState.success(result.valueOrNull!);
    _isRefreshing = false;
    notifyListeners();
  }

  /// Creates a new asset, then reloads the list on success.
  Future<Result<Asset>> createAsset({
    required String name,
    required String category,
    required double value,
    required DateTime acquisitionDate,
    String notes = '',
  }) async {
    final result = await _createAssetUseCase.execute(CreateAssetInput(
      workspaceId: workspaceId,
      name: name,
      category: category,
      value: value,
      acquisitionDate: acquisitionDate,
      notes: notes,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Updates an asset's name/category/value/acquisition date/notes, then
  /// reloads the list on success. Status is intentionally not settable
  /// here — use [archiveAsset]/[disposeAsset].
  Future<Result<Asset>> updateAsset({
    required AssetId assetId,
    String? name,
    String? category,
    double? value,
    DateTime? acquisitionDate,
    String? notes,
  }) async {
    final result = await _updateAssetUseCase.execute(UpdateAssetInput(
      assetId: assetId,
      workspaceId: workspaceId,
      name: name,
      category: category,
      value: value,
      acquisitionDate: acquisitionDate,
      notes: notes,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Archives an asset, then reloads the list on success.
  Future<Result<Asset>> archiveAsset(AssetId assetId) async {
    final result = await _archiveAssetUseCase.execute(
      ArchiveAssetInput(assetId: assetId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Disposes an asset (sold/given away/scrapped), then reloads the list
  /// on success.
  Future<Result<Asset>> disposeAsset(AssetId assetId) async {
    final result = await _disposeAssetUseCase.execute(
      DisposeAssetInput(assetId: assetId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Soft-deletes an asset, then reloads the list on success.
  Future<Result<void>> deleteAsset(AssetId assetId) async {
    final result = await _deleteAssetUseCase.execute(
      DeleteAssetInput(assetId: assetId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }
}
