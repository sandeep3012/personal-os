import 'package:application/application.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetAssetInput {
  const GetAssetInput({required this.assetId, required this.workspaceId});

  final AssetId assetId;
  final String workspaceId;
}

/// Returns a single Asset by id. Mirrors `GetNoteUseCase`.
final class GetAssetUseCase implements AsyncUseCase<GetAssetInput, Asset> {
  const GetAssetUseCase({required IAssetRepository assetRepository})
      : _assetRepository = assetRepository;

  final IAssetRepository _assetRepository;

  @override
  Future<Result<Asset>> execute(GetAssetInput input) async {
    try {
      final result = await _assetRepository.findById(
        input.assetId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final asset = result.valueOrNull;
      if (asset == null) {
        return Result.failure(
          AssetsException(message: 'Asset ${input.assetId} not found'),
        );
      }

      return Result.success(asset);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
