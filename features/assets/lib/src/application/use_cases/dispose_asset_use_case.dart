import 'package:application/application.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:platform_core/platform_core.dart';

final class DisposeAssetInput {
  const DisposeAssetInput({
    required this.assetId,
    required this.workspaceId,
  });

  final AssetId assetId;
  final String workspaceId;
}

/// Transitions an Asset to [AssetStatus.disposed] from
/// [AssetStatus.active] — e.g. the asset was sold, given away, or
/// scrapped.
///
/// Rejects (via [Asset.transitionTo]) if the asset is already
/// disposed/archived — mirrors [ArchiveAssetUseCase]'s pattern of failing
/// loudly on an invalid precondition rather than silently accepting a
/// no-op.
final class DisposeAssetUseCase implements AsyncUseCase<DisposeAssetInput, Asset> {
  const DisposeAssetUseCase({required IAssetRepository assetRepository})
      : _assetRepository = assetRepository;

  final IAssetRepository _assetRepository;

  @override
  Future<Result<Asset>> execute(DisposeAssetInput input) async {
    try {
      final findResult = await _assetRepository.findById(
        input.assetId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) {
        return Result.failure(findResult.exceptionOrNull!);
      }

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(
          AssetsException(message: 'Asset ${input.assetId} not found'),
        );
      }

      final disposed = existing.transitionTo(
        AssetStatus.disposed,
        now: DateTime.now(),
      );

      final saveResult = await _assetRepository.save(disposed);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(disposed);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
