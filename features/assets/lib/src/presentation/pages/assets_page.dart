import 'package:design_system/design_system.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:feature_assets/src/presentation/viewmodels/assets_view_model.dart';
import 'package:flutter/material.dart';

/// The asset list screen.
///
/// Supports viewing assets, creating, editing (name/category/value/
/// acquisition date/notes), archiving/disposing (actions inside the edit
/// dialog), and soft-deleting (swipe → dismiss), entirely through
/// [AssetsViewModel]. Contains no business logic: every action delegates
/// to a use case and only displays whatever [Result] comes back — mirrors
/// `NotesPage`/`GoalsPage`.
///
/// Built entirely from `package:design_system` components:
/// [AppStateSwitcher] for Loading/Empty/Error, [DocumentTile] (the design
/// system's generic icon/title/subtitle row — reused as-is, not forked
/// into an Assets-specific widget, per the Design System being frozen)
/// for each row wrapped in a [Dismissible] for swipe-to-delete, and
/// [showAppInputSurface] for create/edit. The acquisition date picker uses
/// Flutter's standard [showDatePicker] — no new design-system component is
/// introduced for that.
///
/// Archived/disposed assets are excluded from this list (a
/// presentation-layer display filter, not a business rule —
/// [AssetsViewModel.state] still holds them; mirrors [NotesPage] excluding
/// archived notes the same way).
final class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key, required this.viewModel});

  final AssetsViewModel viewModel;

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
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
        appBar: AppBar(title: const Text('Assets')),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<Asset>>(
            state: widget.viewModel.state,
            isEmpty: (assets) => _visible(assets).isEmpty,
            emptyIcon: Icons.inventory_2_outlined,
            emptyTitle: 'No assets yet',
            emptyMessage: 'Add an asset to track its value',
            emptyActionLabel: 'Add Asset',
            onEmptyAction: () => _openAssetForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, assets) {
              final items = _visible(assets);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final asset = items[index];
                  return Dismissible(
                    key: ValueKey(asset.id.value),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteAsset(context, asset),
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
                      icon: Icons.inventory_2_outlined,
                      name: asset.name,
                      categoryLabel: _subtitle(asset),
                      onTap: () => _openAssetForm(context, existing: asset),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAssetForm(context),
          tooltip: 'Add asset',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Asset> _visible(List<Asset> assets) =>
      assets.where((a) => a.status == AssetStatus.active).toList();

  String _subtitle(Asset asset) {
    final value = asset.value.toStringAsFixed(2);
    return '${asset.category} · \$$value · ${_formatDate(asset.acquisitionDate)}';
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  Future<void> _archiveAsset(BuildContext context, Asset asset) async {
    final result = await widget.viewModel.archiveAsset(asset.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _disposeAsset(BuildContext context, Asset asset) async {
    final result = await widget.viewModel.disposeAsset(asset.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _deleteAsset(BuildContext context, Asset asset) async {
    final result = await widget.viewModel.deleteAsset(asset.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _openAssetForm(BuildContext context, {Asset? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final categoryController =
        TextEditingController(text: existing?.category ?? '');
    final valueController =
        TextEditingController(text: existing?.value.toString() ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    var acquisitionDate = existing?.acquisitionDate ?? DateTime.now();

    return showAppInputSurface(
      context,
      title: existing == null ? 'Add Asset' : 'Edit Asset',
      onSave: () => _saveAssetForm(
        context,
        existing: existing,
        nameController: nameController,
        categoryController: categoryController,
        valueController: valueController,
        notesController: notesController,
        acquisitionDate: () => acquisitionDate,
      ),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(label: 'Name', controller: nameController, autofocus: true),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(label: 'Category', controller: categoryController),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Value',
              controller: valueController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Acquired on'),
              subtitle: Text(_formatDate(acquisitionDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: acquisitionDate,
                  firstDate: DateTime(acquisitionDate.year - 50),
                  lastDate: DateTime(acquisitionDate.year + 5),
                );
                if (picked != null) setState(() => acquisitionDate = picked);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Notes (optional)',
              controller: notesController,
            ),
            if (existing != null && existing.status == AssetStatus.active) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _disposeAsset(context, existing);
                    },
                    icon: const Icon(Icons.sell_outlined),
                    label: const Text('Dispose'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _archiveAsset(context, existing);
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

  Future<void> _saveAssetForm(
    BuildContext context, {
    required Asset? existing,
    required TextEditingController nameController,
    required TextEditingController categoryController,
    required TextEditingController valueController,
    required TextEditingController notesController,
    required DateTime Function() acquisitionDate,
  }) async {
    Navigator.of(context).pop();

    final value = double.tryParse(valueController.text) ?? 0;

    final result = existing == null
        ? await widget.viewModel.createAsset(
            name: nameController.text,
            category: categoryController.text,
            value: value,
            acquisitionDate: acquisitionDate(),
            notes: notesController.text,
          )
        : await widget.viewModel.updateAsset(
            assetId: existing.id,
            name: nameController.text,
            category: categoryController.text,
            value: value,
            acquisitionDate: acquisitionDate(),
            notes: notesController.text,
          );

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
