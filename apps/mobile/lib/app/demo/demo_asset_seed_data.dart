import 'package:feature_assets/assets.dart';

/// Seeds a fresh [IAssetDatabaseExecutor] with realistic Assets sample data
/// for Demo Mode. Mirrors `DemoCalendarSeedData`/`DemoNoteSeedData`/
/// `DemoGoalSeedData` exactly — writes directly via `INSERT INTO ...`, the
/// same seam `apps/mobile`'s own bootstrap tests use, since
/// `feature_assets`'s internal schema/DAO classes aren't part of its public
/// barrel.
abstract final class DemoAssetSeedData {
  /// Inserts a realistic demo dataset into [executor] for [workspaceId]: a
  /// mix of active assets and one archived asset — archiving is a user
  /// action, but including one demonstrates the "archived assets are hidden
  /// from the list" behavior in Demo Mode too.
  static Future<void> seed(
    IAssetDatabaseExecutor executor, {
    required String workspaceId,
  }) async {
    final now = DateTime.now();
    final createdAt = now.toIso8601String();

    var seq = 0;
    String nextId() => 'demo-asset-${++seq}';

    Future<void> insertAsset({
      required String name,
      required String category,
      required double value,
      required DateTime acquisitionDate,
      String notes = '',
      String status = 'active',
    }) =>
        executor.execute(
          'INSERT INTO assets '
          '(asset_id, workspace_id, name, category, value, '
          'acquisition_date, notes, status, created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            nextId(),
            workspaceId,
            name,
            category,
            value,
            acquisitionDate.toIso8601String(),
            notes,
            status,
            createdAt,
            createdAt,
            null,
          ],
        );

    await insertAsset(
      name: 'MacBook Pro 16"',
      category: 'Electronics',
      value: 2499,
      acquisitionDate: now.subtract(const Duration(days: 400)),
      notes: 'Primary work laptop.',
    );
    await insertAsset(
      name: 'Toyota Camry',
      category: 'Vehicle',
      value: 24000,
      acquisitionDate: now.subtract(const Duration(days: 900)),
    );
    await insertAsset(
      name: 'Home Studio Camera',
      category: 'Electronics',
      value: 1200,
      acquisitionDate: now.subtract(const Duration(days: 120)),
      notes: 'Used for video calls and content creation.',
    );
    await insertAsset(
      name: 'Vintage Watch',
      category: 'Collectibles',
      value: 3200,
      acquisitionDate: now.subtract(const Duration(days: 1500)),
    );
    await insertAsset(
      name: 'Old Gaming Console',
      category: 'Electronics',
      value: 150,
      acquisitionDate: now.subtract(const Duration(days: 2000)),
      status: 'archived',
    );
  }
}
