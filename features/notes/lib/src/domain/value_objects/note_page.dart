import 'package:feature_notes/src/domain/entities/note.dart';

/// A single page of [Note] results from [SearchNotesUseCase]. Mirrors
/// Goals' `GoalPage`.
final class NotePage {
  const NotePage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<Note> items;
  final int totalCount;
  final bool hasNextPage;
}
