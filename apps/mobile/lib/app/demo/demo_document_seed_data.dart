import 'package:feature_documents/documents.dart';

/// Seeds a fresh [IDocumentDatabaseExecutor] with realistic Documents sample
/// data for Demo Mode. Mirrors `DemoAssetSeedData`/`DemoNoteSeedData`
/// exactly — writes directly via `INSERT INTO ...`, the same seam
/// `apps/mobile`'s own bootstrap tests use, since `feature_documents`'s
/// internal schema/DAO classes aren't part of its public barrel.
abstract final class DemoDocumentSeedData {
  /// Inserts a realistic demo dataset into [executor] for [workspaceId]: a
  /// mix of active documents and one archived document — archiving is a
  /// user action, but including one demonstrates the "archived documents are
  /// hidden from the list" behavior in Demo Mode too.
  static Future<void> seed(
    IDocumentDatabaseExecutor executor, {
    required String workspaceId,
  }) async {
    final now = DateTime.now();
    final createdAt = now.toIso8601String();

    var seq = 0;
    String nextId() => 'demo-document-${++seq}';

    Future<void> insertDocument({
      required String title,
      required String type,
      String referenceLocation = '',
      String notes = '',
      List<String> tags = const [],
      String status = 'active',
    }) {
      final encodedTags =
          tags.isEmpty ? '' : '|${tags.join('|')}|';
      return executor.execute(
        'INSERT INTO documents '
        '(document_id, workspace_id, title, type, reference_location, notes, '
        'tags, status, created_at, updated_at, deleted_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          nextId(),
          workspaceId,
          title,
          type,
          referenceLocation,
          notes,
          encodedTags,
          status,
          createdAt,
          createdAt,
          null,
        ],
      );
    }

    await insertDocument(
      title: 'Home Lease Agreement',
      type: 'Contract',
      referenceLocation: 'file:///documents/lease-agreement.pdf',
      notes: 'Signed copy, renews annually.',
      tags: const ['legal', 'home'],
    );
    await insertDocument(
      title: 'Passport',
      type: 'Identification',
      referenceLocation: 'file:///documents/passport-scan.pdf',
      tags: const ['identity', 'travel'],
    );
    await insertDocument(
      title: 'Car Insurance Policy',
      type: 'Insurance',
      referenceLocation: 'file:///documents/car-insurance.pdf',
      notes: 'Policy renews every 6 months.',
      tags: const ['insurance', 'vehicle'],
    );
    await insertDocument(
      title: 'Laptop Warranty Card',
      type: 'Warranty',
      referenceLocation: 'file:///documents/laptop-warranty.pdf',
      tags: const ['electronics'],
    );
    await insertDocument(
      title: 'Old Rental Agreement',
      type: 'Contract',
      referenceLocation: 'file:///documents/old-rental-agreement.pdf',
      tags: const ['legal', 'home'],
      status: 'archived',
    );
  }
}
