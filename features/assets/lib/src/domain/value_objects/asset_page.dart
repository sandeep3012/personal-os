import 'package:feature_assets/src/domain/entities/asset.dart';

/// A single page of [Asset] results from `SearchAssetsUseCase`. Mirrors
/// Notes' `NotePage`.
final class AssetPage {
  const AssetPage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<Asset> items;
  final int totalCount;
  final bool hasNextPage;
}
