import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';

/// A Document aggregate root — metadata about a real-world or external
/// document a user wants to track (mirrors Notes/Goals' standalone-aggregate
/// shape). There is no owning Folder/Collection entity; grouping, if ever
/// introduced, happens through the platform Entity Linking Service, not
/// through a field on this entity.
///
/// This entity is METADATA ONLY — it never stores file bytes. [referenceLocation]
/// is a plain string pointer (a URI, file path, or similar) to where the
/// actual document lives; real file upload/blob storage is out of scope for
/// this feature (see DOC-031_Finance_Domain_Design.md for how Finance's
/// attachment concept is similarly metadata-oriented).
///
/// Business invariants enforced here:
/// - [title] must not be empty and must not exceed 200 characters (mirrors
///   Note/Goal/Task/Habit/Asset's title invariant).
/// - [type] must not be empty and must not exceed 100 characters — mirrors
///   Assets'/Finance's plain-string category pattern, not a closed enum.
/// - [referenceLocation] must not exceed 2,000 characters.
/// - [notes] must not exceed 20,000 characters (mirrors `Note.content`).
/// - [tags] entries are never empty strings and never duplicated (case
///   sensitive) — enforced by normalizing on construction (mirrors `Note.tags`).
/// - Status transitions are only permitted per the approved transition
///   table — enforced by [transitionTo], not by direct field mutation
///   (this class has no public status setter).
final class Document {
  Document({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.referenceLocation = '',
    this.notes = '',
    List<String> tags = const [],
  }) : tags = _normalizeTags(tags) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const DocumentsException(
        message: 'Document title must not be empty',
      );
    }
    if (title.length > 200) {
      throw const DocumentsException(
        message: 'Document title must not exceed 200 characters',
      );
    }
    final trimmedType = type.trim();
    if (trimmedType.isEmpty) {
      throw const DocumentsException(
        message: 'Document type must not be empty',
      );
    }
    if (type.length > 100) {
      throw const DocumentsException(
        message: 'Document type must not exceed 100 characters',
      );
    }
    if (referenceLocation.length > 2000) {
      throw const DocumentsException(
        message: 'Document referenceLocation must not exceed 2000 characters',
      );
    }
    if (notes.length > 20000) {
      throw const DocumentsException(
        message: 'Document notes must not exceed 20000 characters',
      );
    }
  }

  final DocumentId id;
  final String workspaceId;
  final String title;

  /// Free-text type/category label (e.g. "Contract", "Receipt", "ID") —
  /// mirrors Assets'/Finance's plain-string category, not a closed enum.
  final String type;

  /// A metadata-only pointer to where the actual document lives (a URI, file
  /// path, or similar). No file bytes are ever stored here or anywhere in
  /// this feature. Defaults to an empty string.
  final String referenceLocation;

  /// Optional free-text notes. Defaults to an empty string.
  final String notes;

  /// Free-text labels attached to this document. Never contains empty
  /// strings or duplicates (case sensitive) — see [_normalizeTags]. Mirrors
  /// `Note.tags`.
  final List<String> tags;

  final DocumentStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  static List<String> _normalizeTags(List<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final rawTag in tags) {
      final tag = rawTag.trim();
      if (tag.isEmpty) continue;
      if (seen.add(tag)) result.add(tag);
    }
    return List.unmodifiable(result);
  }

  /// Returns a copy of this document with the supplied fields replaced.
  ///
  /// Does not change [status] — use [transitionTo] for status changes.
  /// Mirrors `Note.copyWith`/`Asset.copyWith` rejecting status as an
  /// updatable field.
  Document copyWith({
    String? title,
    String? type,
    String? referenceLocation,
    String? notes,
    List<String>? tags,
    DateTime? updatedAt,
  }) =>
      Document(
        id: id,
        workspaceId: workspaceId,
        title: title ?? this.title,
        type: type ?? this.type,
        referenceLocation: referenceLocation ?? this.referenceLocation,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy of this document transitioned to [next].
  ///
  /// Throws [DocumentsException] if [next] is not reachable from [status]
  /// per the approved transition table:
  ///
  /// ```
  /// active   -> archived
  /// archived -> (none — terminal)
  /// ```
  Document transitionTo(DocumentStatus next, {required DateTime now}) {
    if (!status.canTransitionTo(next)) {
      throw DocumentsException(
        message:
            'Cannot transition Document from ${status.name} to ${next.name}',
      );
    }
    return Document(
      id: id,
      workspaceId: workspaceId,
      title: title,
      type: type,
      referenceLocation: referenceLocation,
      notes: notes,
      tags: tags,
      status: next,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Document && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Document(id: $id, title: $title, status: ${status.name})';
}
