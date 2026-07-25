import 'package:feature_assets/src/data/dao/asset_dao.dart';
import 'package:feature_assets/src/data/mappers/asset_mapper.dart';
import 'package:feature_assets/src/data/models/asset_query_filter.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_page.dart';
import 'package:feature_assets/src/domain/value_objects/asset_query.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:platform_core/platform_core.dart';

/// SQLite-backed implementation of [IAssetRepository].
///
/// Pure orchestration: delegates all SQL to [AssetDao] and all entity/row
/// conversion to [AssetMapper]. Never builds SQL, never applies business
/// rules — those responsibilities belong to the DAO, the mapper, and the
/// domain entity respectively. Mirrors Notes' `NoteRepository`.
final class AssetRepository implements IAssetRepository {
  const AssetRepository({
    required AssetDao assetDao,
    required AssetMapper assetMapper,
  })  : _assetDao = assetDao,
        _assetMapper = assetMapper;

  final AssetDao _assetDao;
  final AssetMapper _assetMapper;

  @override
  FutureResult<Asset?> findById(
    AssetId id, {
    required String workspaceId,
  }) async {
    try {
      final row = await _assetDao.findById(id.value, workspaceId: workspaceId);
      if (row == null) return const Result.success(null);
      return Result.success(_assetMapper.toEntity(row));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Asset>> findAll({required String workspaceId}) async {
    try {
      final rows = await _assetDao.findAll(workspaceId);
      return Result.success(rows.map(_assetMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<List<Asset>> findByStatus(
    AssetStatus status, {
    required String workspaceId,
  }) async {
    try {
      final rows = await _assetDao.findByStatus(
        status.name,
        workspaceId: workspaceId,
      );
      return Result.success(rows.map(_assetMapper.toEntity).toList());
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<AssetPage> search(AssetQuery query) async {
    try {
      final filter = AssetQueryFilter(
        workspaceId: query.workspaceId,
        status: query.status?.name,
        nameContains: query.nameContains,
        categoryContains: query.categoryContains,
        pageIndex: query.pageIndex,
        pageSize: query.pageSize,
      );
      final result = await _assetDao.query(filter);
      final end = (query.pageIndex + 1) * query.pageSize;

      return Result.success(AssetPage(
        items: result.items.map(_assetMapper.toEntity).toList(),
        totalCount: result.totalCount,
        hasNextPage: end < result.totalCount,
      ));
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> save(Asset asset) async {
    try {
      final row = _assetMapper.toRow(asset);
      final alreadyExists = await _assetDao.exists(
        asset.id.value,
        workspaceId: asset.workspaceId,
      );
      if (alreadyExists) {
        await _assetDao.update(row);
      } else {
        await _assetDao.insert(row);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  @override
  FutureResult<void> softDelete(
    AssetId id, {
    required String workspaceId,
  }) async {
    try {
      await _assetDao.softDelete(
        id.value,
        workspaceId: workspaceId,
        deletedAt: DateTime.now(),
      );
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(_translate(error, stackTrace));
    }
  }

  /// Translates any failure raised by the DAO or mapper into a
  /// [AssetsException] so callers never see a raw database or
  /// persistence-layer exception.
  AppException _translate(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return AssetsException(
      message: 'Asset repository operation failed: $error',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
