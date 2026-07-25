import 'package:application/application.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:platform_core/platform_core.dart';

final class ArchiveAssetInput {
  const ArchiveAssetInput({
    required this.assetId,
    required this.workspaceId,
  });

  final AssetId assetId;
  final String workspaceId;
}

/// Transitions an Asset to [AssetStatus.archived] from
/// [AssetStatus.active].
///
/// Rejects (via [Asset.transitionTo]) if the asset is already
/// archived/disposed — mirrors `ArchiveNoteUseCase`'s pattern of failing
/// loudly on an invalid precondition rather than silently accepting a
/// no-op.
final class ArchiveAssetUseCase implements AsyncUseCase<ArchiveAssetInput, Asset> {
  const ArchiveAssetUseCase({required IAssetRepository assetRepository})
      : _assetRepository = assetRepository;

  final IAssetRepository _assetRepository;

  @override
  Future<Result<Asset>> execute(ArchiveAssetInput input) async {
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

      final archived = existing.transitionTo(
        AssetStatus.archived,
        now: DateTime.now(),
      );

      final saveResult = await _assetRepository.save(archived);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(archived);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
