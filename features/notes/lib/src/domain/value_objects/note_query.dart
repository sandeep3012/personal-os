import 'package:feature_notes/src/domain/value_objects/note_status.dart';

/// Filter and pagination parameters for [SearchNotesUseCase] (mirrors
/// Goals' `GoalQuery` shape).
///
/// All filter fields are optional — absent fields impose no constraint.
/// [titleContains]/[contentContains]/[tagContains] narrow additively (each
/// present field ANDs another condition onto the query) rather than
/// searching across fields with OR semantics — mirrors how Goals' single
/// `nameContains` filter is applied. Results are paginated via
/// [pageIndex]/[pageSize].
final class NoteQuery {
  const NoteQuery({
    required this.workspaceId,
    this.status,
    this.titleContains,
    this.contentContains,
    this.tagContains,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  final String workspaceId;
  final NoteStatus? status;
  final String? titleContains;
  final String? contentContains;
  final String? tagContains;
  final int pageIndex;
  final int pageSize;
}
