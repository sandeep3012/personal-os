import 'package:feature_assets/src/domain/value_objects/asset_status.dart';

/// Filter and pagination parameters for `SearchAssetsUseCase` (mirrors
/// Notes' `NoteQuery` shape).
///
/// All filter fields are optional — absent fields impose no constraint.
/// [nameContains]/[categoryContains] narrow additively (each present field
/// ANDs another condition onto the query) rather than searching across
/// fields with OR semantics — mirrors how Notes applies its filters.
/// Results are paginated via [pageIndex]/[pageSize].
final class AssetQuery {
  const AssetQuery({
    required this.workspaceId,
    this.status,
    this.nameContains,
    this.categoryContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final AssetStatus? status;
  final String? nameContains;
  final String? categoryContains;
  final int pageIndex;
  final int pageSize;
}
