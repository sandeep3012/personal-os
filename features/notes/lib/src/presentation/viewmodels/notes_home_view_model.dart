import 'package:application/application.dart';
import 'package:feature_notes/src/application/use_cases/get_notes_use_case.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter/foundation.dart';

/// The Home Dashboard's Notes summary data — a presentation-layer
/// computation over [GetNotesUseCase]'s result, not a domain type. Mirrors
/// `GoalsDashboardSummary`.
final class NotesDashboardSummary {
  const NotesDashboardSummary({
    required this.activeCount,
    required this.archivedCount,
  });

  /// Count of notes with [NoteStatus.active].
  final int activeCount;

  /// Count of notes with [NoteStatus.archived].
  final int archivedCount;
}

/// Drives the Notes [ModuleCard] on [HomeDashboardPage] — mirrors
/// `GoalsHomeViewModel` exactly: a small, isolated aggregator ViewModel
/// distinct from [NotesViewModel] (the full list page).
///
/// No new summary use case is introduced — the counts are computed
/// presentation-side from [GetNotesUseCase]'s result, mirroring how
/// `GoalsDashboardSummary` is assembled.
final class NotesHomeViewModel extends ChangeNotifier {
  NotesHomeViewModel({
    required GetNotesUseCase getNotesUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getNotesUseCase = getNotesUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;
  String get workspaceId => _workspaceContext.workspaceId;

  final GetNotesUseCase _getNotesUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<NotesDashboardSummary> _state = const AsyncState.loading();

  /// The current load state: loading, success (with the summary), or error.
  AsyncState<NotesDashboardSummary> get state => _state;

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

    final result = await _getNotesUseCase.execute(
      GetNotesInput(workspaceId: workspaceId),
    );

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final notes = result.valueOrNull!;
    final activeCount = notes.where((n) => n.status == NoteStatus.active).length;
    final archivedCount =
        notes.where((n) => n.status == NoteStatus.archived).length;

    _state = AsyncState.success(NotesDashboardSummary(
      activeCount: activeCount,
      archivedCount: archivedCount,
    ));
    _isRefreshing = false;
    notifyListeners();
  }
}
