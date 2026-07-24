import 'package:application/application.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetAssetsInput {
  const GetAssetsInput({required this.workspaceId});

  final String workspaceId;
}

/// Returns all non-deleted assets in the workspace, regardless of status —
/// filtering by status is [SearchAssetsUseCase]'s job. Mirrors
/// `GetNotesUseCase` in shape.
final class GetAssetsUseCase implements AsyncUseCase<GetAssetsInput, List<Asset>> {
  const GetAssetsUseCase({required IAssetRepository assetRepository})
      : _assetRepository = assetRepository;

  final IAssetRepository _assetRepository;

  @override
  Future<Result<List<Asset>>> execute(GetAssetsInput input) async {
    try {
      final result =
          await _assetRepository.findAll(workspaceId: input.workspaceId);
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return Result.success(result.valueOrNull!);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
