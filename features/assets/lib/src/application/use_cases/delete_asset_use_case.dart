import 'package:application/application.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteAssetInput {
  const DeleteAssetInput({
    required this.assetId,
    required this.workspaceId,
  });

  final AssetId assetId;
  final String workspaceId;
}

/// Soft-deletes an Asset.
///
/// No precondition beyond existence — mirrors `DeleteNoteUseCase`; Asset is
/// a standalone aggregate with no cross-entity precondition.
final class DeleteAssetUseCase implements AsyncUseCase<DeleteAssetInput, void> {
  const DeleteAssetUseCase({required IAssetRepository assetRepository})
      : _assetRepository = assetRepository;

  final IAssetRepository _assetRepository;

  @override
  Future<Result<void>> execute(DeleteAssetInput input) async {
    try {
      final deleteResult = await _assetRepository.softDelete(
        input.assetId,
        workspaceId: input.workspaceId,
      );
      if (deleteResult.isFailure) {
        return Result.failure(deleteResult.exceptionOrNull!);
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
