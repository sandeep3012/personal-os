import 'package:application/application.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateAssetInput {
  const UpdateAssetInput({
    required this.assetId,
    required this.workspaceId,
    this.name,
    this.category,
    this.value,
    this.acquisitionDate,
    this.notes,
  });

  final AssetId assetId;
  final String workspaceId;

  /// New name. `null` keeps the existing name.
  final String? name;

  /// New category. `null` keeps the existing category.
  final String? category;

  /// New value. `null` keeps the existing value.
  final double? value;

  /// New acquisition date. `null` keeps the existing acquisition date.
  final DateTime? acquisitionDate;

  /// New notes. `null` keeps the existing notes.
  final String? notes;
}

/// Updates the mutable, non-status fields of an existing Asset.
///
/// `status` is intentionally absent from [UpdateAssetInput] — status
/// changes go through [DisposeAssetUseCase]/[ArchiveAssetUseCase],
/// mirroring `UpdateNoteUseCase` rejecting status as an input.
final class UpdateAssetUseCase implements AsyncUseCase<UpdateAssetInput, Asset> {
  const UpdateAssetUseCase({required IAssetRepository assetRepository})
      : _assetRepository = assetRepository;

  final IAssetRepository _assetRepository;

  @override
  Future<Result<Asset>> execute(UpdateAssetInput input) async {
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

      final updated = existing.copyWith(
        name: input.name,
        category: input.category,
        value: input.value,
        acquisitionDate: input.acquisitionDate,
        notes: input.notes,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _assetRepository.save(updated);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
