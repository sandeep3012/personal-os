import 'package:application/application.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:platform_core/platform_core.dart';

final class CreateAssetInput {
  const CreateAssetInput({
    required this.workspaceId,
    required this.name,
    required this.category,
    required this.value,
    required this.acquisitionDate,
    this.notes = '',
  });

  final String workspaceId;
  final String name;
  final String category;
  final double value;
  final DateTime acquisitionDate;
  final String notes;
}

/// Creates a new Asset and persists it via [IAssetRepository].
///
/// New assets always start at [AssetStatus.active] — mirrors
/// `CreateNoteUseCase` in shape. All validation (name/category non-empty
/// and length, value non-negative, notes length) is enforced by the
/// [Asset] entity constructor itself — this use case performs no
/// additional validation.
final class CreateAssetUseCase implements AsyncUseCase<CreateAssetInput, Asset> {
  CreateAssetUseCase({
    required IAssetRepository assetRepository,
    required IdGenerator idGenerator,
  })  : _assetRepository = assetRepository,
        _idGenerator = idGenerator;

  final IAssetRepository _assetRepository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<Asset>> execute(CreateAssetInput input) async {
    try {
      final now = DateTime.now();
      final asset = Asset(
        id: AssetId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        name: input.name,
        category: input.category,
        value: input.value,
        acquisitionDate: input.acquisitionDate,
        notes: input.notes,
        status: AssetStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _assetRepository.save(asset);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(asset);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
