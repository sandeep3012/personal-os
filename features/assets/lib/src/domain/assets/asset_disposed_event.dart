import 'package:application/application.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';

/// Disposing an asset (sold, given away, scrapped) is a distinct, terminal,
/// business-meaningful transition, not an ordinary field update — mirrors
/// `AssetArchivedEvent`/`NoteArchivedEvent`.
final class AssetDisposedEvent extends DomainEvent {
  const AssetDisposedEvent({
    required this.assetId,
    required this.workspaceId,
    required this.timestamp,
  });

  final AssetId assetId;
  final String workspaceId;
  final DateTime timestamp;
}
