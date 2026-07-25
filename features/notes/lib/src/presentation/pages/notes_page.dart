import 'package:design_system/design_system.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:feature_notes/src/presentation/viewmodels/notes_view_model.dart';
import 'package:flutter/material.dart';

/// The note list screen.
///
/// Supports viewing notes, creating, editing (title/content/tags),
/// archiving (an action inside the edit dialog), and soft-deleting (swipe →
/// dismiss), entirely through [NotesViewModel]. Contains no business logic:
/// every action delegates to a use case and only displays whatever [Result]
/// comes back — mirrors `GoalsPage`/`TasksPage`.
///
/// Built entirely from `package:design_system` components: [AppStateSwitcher]
/// for Loading/Empty/Error, [DocumentTile] (the design system's generic
/// icon/title/subtitle row — reused as-is, not forked into a Notes-specific
/// widget, per the Design System being frozen) for each row wrapped in a
/// [Dismissible] for swipe-to-delete, and [showAppInputSurface] for
/// create/edit.
///
/// Archived notes are excluded from this list (a presentation-layer display
/// filter, not a business rule — [NotesViewModel.state] still holds them;
/// mirrors [GoalsPage] excluding archived goals the same way).
final class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.viewModel});

  final NotesViewModel viewModel;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Notes')),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<Note>>(
            state: widget.viewModel.state,
            isEmpty: (notes) => _visible(notes).isEmpty,
            emptyIcon: Icons.note_outlined,
            emptyTitle: 'No notes yet',
            emptyMessage: 'Add a note to jot something down',
            emptyActionLabel: 'Add Note',
            onEmptyAction: () => _openNoteForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, notes) {
              final items = _visible(notes);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final note = items[index];
                  return Dismissible(
                    key: ValueKey(note.id.value),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteNote(context, note),
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    child: DocumentTile(
                      icon: Icons.note_outlined,
                      name: note.title,
                      categoryLabel: _subtitle(note),
                      onTap: () => _openNoteForm(context, existing: note),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openNoteForm(context),
          tooltip: 'Add note',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Note> _visible(List<Note> notes) =>
      notes.where((n) => n.status != NoteStatus.archived).toList();

  String _subtitle(Note note) {
    final tags = note.tags.isEmpty ? '' : note.tags.map((t) => '#$t').join(' ');
    final preview = note.content.length > 80
        ? '${note.content.substring(0, 80)}…'
        : note.content;
    if (tags.isEmpty) return preview.isEmpty ? 'No content' : preview;
    return preview.isEmpty ? tags : '$preview · $tags';
  }

  Future<void> _archiveNote(BuildContext context, Note note) async {
    final result = await widget.viewModel.archiveNote(note.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _deleteNote(BuildContext context, Note note) async {
    final result = await widget.viewModel.deleteNote(note.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _openNoteForm(BuildContext context, {Note? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    final tagsController = TextEditingController(
      text: existing == null ? '' : existing.tags.join(', '),
    );

    return showAppInputSurface(
      context,
      title: existing == null ? 'Add Note' : 'Edit Note',
      onSave: () => _saveNoteForm(
        context,
        existing: existing,
        titleController: titleController,
        contentController: contentController,
        tagsController: tagsController,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormField(label: 'Title', controller: titleController, autofocus: true),
          const SizedBox(height: AppSpacing.sm),
          AppFormField(
            label: 'Content (optional)',
            controller: contentController,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFormField(
            label: 'Tags, comma separated (optional)',
            controller: tagsController,
          ),
          if (existing != null && existing.status == NoteStatus.active) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _archiveNote(context, existing);
                },
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveNoteForm(
    BuildContext context, {
    required Note? existing,
    required TextEditingController titleController,
    required TextEditingController contentController,
    required TextEditingController tagsController,
  }) async {
    Navigator.of(context).pop();

    final tags = tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final result = existing == null
        ? await widget.viewModel.createNote(
            title: titleController.text,
            content: contentController.text,
            tags: tags,
          )
        : await widget.viewModel.updateNote(
            noteId: existing.id,
            title: titleController.text,
            content: contentController.text,
            tags: tags,
          );

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
