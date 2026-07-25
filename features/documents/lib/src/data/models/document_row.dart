import 'package:feature_documents/src/data/schema/documents_schema.dart';

/// A single, unmapped row from the `documents` table.
///
/// [DocumentRow] is a persistence-layer data shape only — it has no business
/// methods, no validation, and no relationship to the domain `Document`
/// entity. Mapping between [DocumentRow] and `Document` is a repository-layer
/// concern, not a DAO concern. Mirrors Notes' `NoteRow`.
///
/// [tags] is persisted as a single delimited `TEXT` column (pipe-separated,
/// e.g. `|contract|2026|`) rather than a normalized child table — mirrors
/// `NoteRow.tags`.
final class DocumentRow {
  const DocumentRow({
    required this.documentId,
    required this.workspaceId,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.referenceLocation = '',
    this.notes = '',
    this.tags = const [],
    this.deletedAt,
  });

  final String documentId;
  final String workspaceId;
  final String title;
  final String type;
  final String referenceLocation;
  final String notes;
  final List<String> tags;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  static const _tagDelimiter = '|';

  /// Builds a [DocumentRow] from a raw SQL result row.
  factory DocumentRow.fromMap(Map<String, Object?> map) {
    final deletedAtValue = map[DocumentsSchema.documentDeletedAt] as String?;
    return DocumentRow(
      documentId: map[DocumentsSchema.documentId]! as String,
      workspaceId: map[DocumentsSchema.documentWorkspaceId]! as String,
      title: map[DocumentsSchema.documentTitle]! as String,
      type: map[DocumentsSchema.documentType]! as String,
      referenceLocation:
          map[DocumentsSchema.documentReferenceLocation] as String? ?? '',
      notes: map[DocumentsSchema.documentNotes] as String? ?? '',
      tags: _decodeTags(map[DocumentsSchema.documentTags] as String?),
      status: map[DocumentsSchema.documentStatus]! as String,
      createdAt: DateTime.parse(map[DocumentsSchema.documentCreatedAt]! as String),
      updatedAt: DateTime.parse(map[DocumentsSchema.documentUpdatedAt]! as String),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [DocumentsSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        DocumentsSchema.documentId: documentId,
        DocumentsSchema.documentWorkspaceId: workspaceId,
        DocumentsSchema.documentTitle: title,
        DocumentsSchema.documentType: type,
        DocumentsSchema.documentReferenceLocation: referenceLocation,
        DocumentsSchema.documentNotes: notes,
        DocumentsSchema.documentTags: _encodeTags(tags),
        DocumentsSchema.documentStatus: status,
        DocumentsSchema.documentCreatedAt: createdAt.toIso8601String(),
        DocumentsSchema.documentUpdatedAt: updatedAt.toIso8601String(),
        DocumentsSchema.documentDeletedAt: deletedAt?.toIso8601String(),
      };

  static String _encodeTags(List<String> tags) =>
      tags.isEmpty ? '' : '$_tagDelimiter${tags.join(_tagDelimiter)}$_tagDelimiter';

  static List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(_tagDelimiter)
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.documentId == documentId &&
          other.workspaceId == workspaceId &&
          other.title == title &&
          other.type == type &&
          other.referenceLocation == referenceLocation &&
          other.notes == notes &&
          _listEquals(other.tags, tags) &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        documentId,
        workspaceId,
        title,
        type,
        referenceLocation,
        notes,
        Object.hashAll(tags),
        status,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'DocumentRow(documentId: $documentId, title: $title)';
}
