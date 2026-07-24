import 'package:application/application.dart';
import 'package:feature_documents/src/application/use_cases/get_documents_use_case.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter/foundation.dart';

/// The Home Dashboard's Documents summary data — a presentation-layer
/// computation over [GetDocumentsUseCase]'s result, not a domain type.
/// Mirrors `NotesDashboardSummary`.
final class DocumentsDashboardSummary {
  const DocumentsDashboardSummary({
    required this.activeCount,
  });

  /// Count of documents with [DocumentStatus.active].
  final int activeCount;
}

/// Drives the Documents [ModuleCard] on [HomeDashboardPage] — mirrors
/// `NotesHomeViewModel` exactly: a small, isolated aggregator ViewModel
/// distinct from [DocumentsViewModel] (the full list page).
///
/// No new summary use case is introduced — the counts are computed
/// presentation-side from [GetDocumentsUseCase]'s result, mirroring how
/// `NotesDashboardSummary` is assembled.
final class DocumentsHomeViewModel extends ChangeNotifier {
  DocumentsHomeViewModel({
    required GetDocumentsUseCase getDocumentsUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getDocumentsUseCase = getDocumentsUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;
  String get workspaceId => _workspaceContext.workspaceId;

  final GetDocumentsUseCase _getDocumentsUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<DocumentsDashboardSummary> _state = const AsyncState.loading();

  /// The current load state: loading, success (with the summary), or error.
  AsyncState<DocumentsDashboardSummary> get state => _state;

  var _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  Future<void> load() => _fetch(isRefresh: false);
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

    final documents = result.valueOrNull!;
    final active = documents.where((a) => a.status == DocumentStatus.active);
    final activeCount = active.length;

    _state = AsyncState.success(DocumentsDashboardSummary(
      activeCount: activeCount,
    ));
    _isRefreshing = false;
    notifyListeners();
  }
}
