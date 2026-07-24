import 'package:application/application.dart';
import 'package:feature_documents/src/application/use_cases/archive_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/create_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/delete_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/get_documents_use_case.dart';
import 'package:feature_documents/src/application/use_cases/update_document_use_case.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// Drives [DocumentsPage]: loads all documents and exposes create/update/
/// archive/delete operations.
///
/// Depends only on use cases — never on [IDocumentRepository] directly. All
/// business rules (title/type validation, tag normalization,
/// status-transition legality, etc.) are enforced by the use cases and the
/// [Document] entity beneath them; this ViewModel neither duplicates nor
/// bypasses them — it only orchestrates calls and surfaces whatever
/// [Result] they return. Mirrors `NotesViewModel` exactly.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) —
/// this ViewModel never invents or hardcodes a workspace identifier, and
/// reloads automatically when [WorkspaceContext] reports a switch.
final class DocumentsViewModel extends ChangeNotifier {
  DocumentsViewModel({
    required GetDocumentsUseCase getDocumentsUseCase,
    required CreateDocumentUseCase createDocumentUseCase,
    required UpdateDocumentUseCase updateDocumentUseCase,
    required ArchiveDocumentUseCase archiveDocumentUseCase,
    required DeleteDocumentUseCase deleteDocumentUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getDocumentsUseCase = getDocumentsUseCase,
        _createDocumentUseCase = createDocumentUseCase,
        _updateDocumentUseCase = updateDocumentUseCase,
        _archiveDocumentUseCase = archiveDocumentUseCase,
        _deleteDocumentUseCase = deleteDocumentUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetDocumentsUseCase _getDocumentsUseCase;
  final CreateDocumentUseCase _createDocumentUseCase;
  final UpdateDocumentUseCase _updateDocumentUseCase;
  final ArchiveDocumentUseCase _archiveDocumentUseCase;
  final DeleteDocumentUseCase _deleteDocumentUseCase;

  /// Reloads the document list for the newly-active workspace — presentation
  /// plumbing only, mirrors `NotesViewModel._handleWorkspaceChanged`.
  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<Document>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with documents), or error.
  AsyncState<List<Document>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// Loads documents for the first time (or after an error), showing the
  /// full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads documents while keeping the current list visible ([isRefreshing]
  /// becomes `true` instead of resetting [state] to loading).
  Future<void> refresh() => _fetch(isRefresh: true);

  Future<void> _fetch({required bool isRefresh}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _state = const AsyncState.loading();
    }
    notifyListeners();

    final result = await _getDocumentsUseCase.execute(
      GetDocumentsInput(workspaceId: workspaceId),
    );

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    _state = AsyncState.success(result.valueOrNull!);
    _isRefreshing = false;
    notifyListeners();
  }

  /// Creates a new document, then reloads the list on success.
  Future<Result<Document>> createDocument({
    required String title,
    required String type,
    String referenceLocation = '',
    String notes = '',
    List<String> tags = const [],
  }) async {
    final result = await _createDocumentUseCase.execute(CreateDocumentInput(
      workspaceId: workspaceId,
      title: title,
      type: type,
      referenceLocation: referenceLocation,
      notes: notes,
      tags: tags,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Updates a document's title/type/reference location/notes/tags, then
  /// reloads the list on success. Status is intentionally not settable
  /// here — use [archiveDocument].
  Future<Result<Document>> updateDocument({
    required DocumentId documentId,
    String? title,
    String? type,
    String? referenceLocation,
    String? notes,
    List<String>? tags,
  }) async {
    final result = await _updateDocumentUseCase.execute(UpdateDocumentInput(
      documentId: documentId,
      workspaceId: workspaceId,
      title: title,
      type: type,
      referenceLocation: referenceLocation,
      notes: notes,
      tags: tags,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Archives a document, then reloads the list on success.
  Future<Result<Document>> archiveDocument(DocumentId documentId) async {
    final result = await _archiveDocumentUseCase.execute(
      ArchiveDocumentInput(documentId: documentId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Soft-deletes a document, then reloads the list on success.
  Future<Result<void>> deleteDocument(DocumentId documentId) async {
    final result = await _deleteDocumentUseCase.execute(
      DeleteDocumentInput(documentId: documentId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }
}
