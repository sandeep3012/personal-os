import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_page.dart';
import 'package:feature_assets/src/domain/value_objects/asset_query.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [IAssetRepository] for use-case unit tests. Mirrors Notes'
/// `FakeNoteRepository`.
final class FakeAssetRepository implements IAssetRepository {
  final List<Asset> _store = [];

  List<Asset> get store => List.unmodifiable(_store);

  void seed(List<Asset> assets) {
    _store.clear();
    _store.addAll(assets);
  }

  @override
  FutureResult<Asset?> findById(AssetId id, {required String workspaceId}) async =>
      Result.success(_store.where((e) => e.id == id).firstOrNull);

  @override
  FutureResult<List<Asset>> findAll({required String workspaceId}) async =>
      Result.success(List.unmodifiable(_store));

  @override
  FutureResult<List<Asset>> findByStatus(
    AssetStatus status, {
    required String workspaceId,
  }) async =>
      Result.success(
        List.unmodifiable(_store.where((e) => e.status == status).toList()),
      );

  @override
  FutureResult<AssetPage> search(AssetQuery query) async {
    var filtered = _store.where((e) => e.workspaceId == query.workspaceId);
    if (query.status != null) {
      filtered = filtered.where((e) => e.status == query.status);
    }
    if (query.nameContains != null && query.nameContains!.isNotEmpty) {
      filtered = filtered.where(
        (e) => e.name.toLowerCase().contains(query.nameContains!.toLowerCase()),
      );
    }
    if (query.categoryContains != null && query.categoryContains!.isNotEmpty) {
      filtered = filtered.where(
        (e) =>
            e.category.toLowerCase().contains(query.categoryContains!.toLowerCase()),
      );
    }
    final all = filtered.toList();
    final start = query.pageIndex * query.pageSize;
    final end = (start + query.pageSize).clamp(0, all.length);
    final items = start >= all.length ? <Asset>[] : all.sublist(start, end);

    return Result.success(AssetPage(
      items: items,
      totalCount: all.length,
      hasNextPage: end < all.length,
    ));
  }

  @override
  FutureResult<void> save(Asset asset) async {
    _store.removeWhere((e) => e.id == asset.id);
    _store.add(asset);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(AssetId id, {required String workspaceId}) async {
    _store.removeWhere((e) => e.id == id);
    return const Result.success(null);
  }
}
