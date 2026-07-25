import 'package:design_system/design_system.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:feature_documents/src/presentation/viewmodels/documents_view_model.dart';
import 'package:flutter/material.dart';

/// The document list screen.
///
/// Supports viewing documents, creating, editing (title/type/reference
/// location/notes/tags), archiving (action inside the edit dialog), and
/// soft-deleting (swipe → dismiss), entirely through [DocumentsViewModel].
/// Contains no business logic: every action delegates to a use case and
/// only displays whatever [Result] comes back — mirrors `NotesPage`/
/// `AssetsPage`.
///
/// Built entirely from `package:design_system` components:
/// [AppStateSwitcher] for Loading/Empty/Error, [DocumentTile] (the design
/// system's generic icon/title/subtitle row — reused as-is, not forked into
/// a Documents-specific widget, per the Design System being frozen) for
/// each row wrapped in a [Dismissible] for swipe-to-delete, and
/// [showAppInputSurface] for create/edit.
///
/// This screen is METADATA ONLY — [referenceLocation] is a plain string
/// pointer (URI/path); there is no file upload or blob preview here, that
/// is explicitly out of scope for this feature.
///
/// Archived documents are excluded from this list (a presentation-layer
/// display filter, not a business rule — [DocumentsViewModel.state] still
/// holds them; mirrors [NotesPage] excluding archived notes the same way).
final class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, required this.viewModel});

  final DocumentsViewModel viewModel;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
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
        appBar: AppBar(title: const Text('Documents')),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<Document>>(
            state: widget.viewModel.state,
            isEmpty: (documents) => _visible(documents).isEmpty,
            emptyIcon: Icons.description_outlined,
            emptyTitle: 'No documents yet',
            emptyMessage: 'Add a document to track its metadata',
            emptyActionLabel: 'Add Document',
            onEmptyAction: () => _openDocumentForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, documents) {
              final items = _visible(documents);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final document = items[index];
                  return Dismissible(
                    key: ValueKey(document.id.value),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteDocument(context, document),
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
                      icon: Icons.description_outlined,
                      name: document.title,
                      categoryLabel: _subtitle(document),
                      onTap: () => _openDocumentForm(context, existing: document),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openDocumentForm(context),
          tooltip: 'Add document',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Document> _visible(List<Document> documents) =>
      documents.where((d) => d.status == DocumentStatus.active).toList();

  String _subtitle(Document document) {
    final tagsSuffix = document.tags.isEmpty ? '' : ' · ${document.tags.join(', ')}';
    return '${document.type}$tagsSuffix';
  }

  Future<void> _archiveDocument(BuildContext context, Document document) async {
    final result = await widget.viewModel.archiveDocument(document.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _deleteDocument(BuildContext context, Document document) async {
    final result = await widget.viewModel.deleteDocument(document.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _openDocumentForm(BuildContext context, {Document? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final typeController = TextEditingController(text: existing?.type ?? '');
    final referenceLocationController =
        TextEditingController(text: existing?.referenceLocation ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final tagsController =
        TextEditingController(text: existing?.tags.join(', ') ?? '');

    return showAppInputSurface(
      context,
      title: existing == null ? 'Add Document' : 'Edit Document',
      onSave: () => _saveDocumentForm(
        context,
        existing: existing,
        titleController: titleController,
        typeController: typeController,
        referenceLocationController: referenceLocationController,
        notesController: notesController,
        tagsController: tagsController,
      ),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(label: 'Title', controller: titleController, autofocus: true),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(label: 'Type', controller: typeController),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Reference location (optional)',
              controller: referenceLocationController,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Tags (comma-separated, optional)',
              controller: tagsController,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Notes (optional)',
              controller: notesController,
            ),
            if (existing != null && existing.status == DocumentStatus.active) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _archiveDocument(context, existing);
                    },
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Archive'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveDocumentForm(
    BuildContext context, {
    required Document? existing,
    required TextEditingController titleController,
    required TextEditingController typeController,
    required TextEditingController referenceLocationController,
    required TextEditingController notesController,
    required TextEditingController tagsController,
  }) async {
    Navigator.of(context).pop();

    final tags = tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final result = existing == null
        ? await widget.viewModel.createDocument(
            title: titleController.text,
            type: typeController.text,
            referenceLocation: referenceLocationController.text,
            notes: notesController.text,
            tags: tags,
          )
        : await widget.viewModel.updateDocument(
            documentId: existing.id,
            title: titleController.text,
            type: typeController.text,
            referenceLocation: referenceLocationController.text,
            notes: notesController.text,
            tags: tags,
          );

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
