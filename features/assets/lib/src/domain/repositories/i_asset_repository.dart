import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_page.dart';
import 'package:feature_assets/src/domain/value_objects/asset_query.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Asset persistence, expressed in domain terms. Mirrors
/// `INoteRepository`.
///
/// Implementations are internal to the Assets feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-delete is the only supported removal strategy, mirroring Notes.
abstract interface class IAssetRepository {
  /// Returns the [Asset] with [id] within [workspaceId], or `null` if no
  /// matching, non-deleted asset exists.
  FutureResult<Asset?> findById(AssetId id, {required String workspaceId});

  /// Returns all non-deleted assets within [workspaceId], regardless of
  /// status — filtering by status is `SearchAssetsUseCase`'s
  /// responsibility, not this method's.
  ///
  /// Returns an empty list when no assets exist — never fails for an empty
  /// workspace.
  FutureResult<List<Asset>> findAll({required String workspaceId});

  /// Returns all non-deleted assets within [workspaceId] whose status
  /// equals [status].
  FutureResult<List<Asset>> findByStatus(
    AssetStatus status, {
    required String workspaceId,
  });

  /// Executes [query] and returns the matching page of assets alongside the
  /// total match count (pre-pagination). Mirrors `INoteRepository.search`.
  FutureResult<AssetPage> search(AssetQuery query);

  /// Persists [asset]. Creates it if it is new; updates it if it already
  /// exists.
  FutureResult<void> save(Asset asset);

  /// Marks the asset identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the asset has already been removed.
  /// Soft-delete only; hard deletion is not supported (mirrors Notes).
  FutureResult<void> softDelete(AssetId id, {required String workspaceId});
}
