import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_page.dart';
import 'package:feature_notes/src/domain/value_objects/note_query.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [INoteRepository] for use-case unit tests. Mirrors Goals'
/// `FakeGoalRepository`.
final class FakeNoteRepository implements INoteRepository {
  final List<Note> _store = [];

  List<Note> get store => List.unmodifiable(_store);

  void seed(List<Note> notes) {
    _store.clear();
    _store.addAll(notes);
  }

  @override
  FutureResult<Note?> findById(NoteId id, {required String workspaceId}) async =>
      Result.success(_store.where((n) => n.id == id).firstOrNull);

  @override
  FutureResult<List<Note>> findAll({required String workspaceId}) async =>
      Result.success(List.unmodifiable(_store));

  @override
  FutureResult<List<Note>> findByStatus(
    NoteStatus status, {
    required String workspaceId,
  }) async =>
      Result.success(
        List.unmodifiable(_store.where((n) => n.status == status).toList()),
      );

  @override
  FutureResult<NotePage> search(NoteQuery query) async {
    var filtered = _store.where((n) => n.workspaceId == query.workspaceId);
    if (query.status != null) {
      filtered = filtered.where((n) => n.status == query.status);
    }
    if (query.titleContains != null && query.titleContains!.isNotEmpty) {
      filtered = filtered.where(
        (n) => n.title.toLowerCase().contains(query.titleContains!.toLowerCase()),
      );
    }
    if (query.contentContains != null && query.contentContains!.isNotEmpty) {
      filtered = filtered.where(
        (n) =>
            n.content.toLowerCase().contains(query.contentContains!.toLowerCase()),
      );
    }
    if (query.tagContains != null && query.tagContains!.isNotEmpty) {
      filtered = filtered.where(
        (n) => n.tags.any(
          (t) => t.toLowerCase().contains(query.tagContains!.toLowerCase()),
        ),
      );
    }
    final all = filtered.toList();
    final start = query.pageIndex * query.pageSize;
    final end = (start + query.pageSize).clamp(0, all.length);
    final items = start >= all.length ? <Note>[] : all.sublist(start, end);

    return Result.success(NotePage(
      items: items,
      totalCount: all.length,
      hasNextPage: end < all.length,
    ));
  }

  @override
  FutureResult<void> save(Note note) async {
    _store.removeWhere((n) => n.id == note.id);
    _store.add(note);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(NoteId id, {required String workspaceId}) async {
    _store.removeWhere((n) => n.id == id);
    return const Result.success(null);
  }
}
