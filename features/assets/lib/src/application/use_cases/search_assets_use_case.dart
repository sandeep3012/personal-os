import 'package:application/application.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/domain/value_objects/asset_page.dart';
import 'package:feature_assets/src/domain/value_objects/asset_query.dart';
import 'package:platform_core/platform_core.dart';

/// Executes an [AssetQuery] and returns a paginated [AssetPage].
///
/// Delegates directly to [IAssetRepository.search], which performs
/// SQL-level filtering and pagination via [AssetDao.query] — orchestration
/// only, no in-memory filtering here. Mirrors `SearchNotesUseCase`.
final class SearchAssetsUseCase implements AsyncUseCase<AssetQuery, AssetPage> {
  const SearchAssetsUseCase({required IAssetRepository assetRepository})
      : _assetRepository = assetRepository;

  final IAssetRepository _assetRepository;

  @override
  Future<Result<AssetPage>> execute(AssetQuery input) =>
      _assetRepository.search(input);
}
