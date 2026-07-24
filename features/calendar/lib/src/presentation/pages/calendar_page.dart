import 'package:design_system/design_system.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:feature_calendar/src/presentation/viewmodels/calendar_view_model.dart';
import 'package:flutter/material.dart';

/// The event list screen.
///
/// Supports viewing events, creating, editing (title/location/description/
/// time range), archiving (an action inside the edit dialog), and
/// soft-deleting (swipe → dismiss), entirely through [CalendarViewModel].
/// Contains no business logic: every action delegates to a use case and
/// only displays whatever [Result] comes back — mirrors `NotesPage`/
/// `GoalsPage`.
///
/// Built entirely from `package:design_system` components:
/// [AppStateSwitcher] for Loading/Empty/Error, [DocumentTile] (the design
/// system's generic icon/title/subtitle row — reused as-is, not forked
/// into a Calendar-specific widget, per the Design System being frozen)
/// for each row wrapped in a [Dismissible] for swipe-to-delete, and
/// [showAppInputSurface] for create/edit. Start/end pickers use Flutter's
/// standard [showDatePicker]/[showTimePicker] — no new design-system
/// component is introduced for that.
///
/// Archived events are excluded from this list (a presentation-layer
/// display filter, not a business rule — [CalendarViewModel.state] still
/// holds them; mirrors [NotesPage] excluding archived notes the same way).
final class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.viewModel});

  final CalendarViewModel viewModel;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
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
        appBar: AppBar(title: const Text('Calendar')),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<Event>>(
            state: widget.viewModel.state,
            isEmpty: (events) => _visible(events).isEmpty,
            emptyIcon: Icons.event_outlined,
            emptyTitle: 'No events yet',
            emptyMessage: 'Add an event to plan something',
            emptyActionLabel: 'Add Event',
            onEmptyAction: () => _openEventForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, events) {
              final items = _visible(events);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final event = items[index];
                  return Dismissible(
                    key: ValueKey(event.id.value),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteEvent(context, event),
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
                      icon: Icons.event_outlined,
                      name: event.title,
                      categoryLabel: _subtitle(event),
                      onTap: () => _openEventForm(context, existing: event),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openEventForm(context),
          tooltip: 'Add event',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Event> _visible(List<Event> events) =>
      events.where((e) => e.status != EventStatus.archived).toList();

  String _subtitle(Event event) {
    final range = '${_formatDateTime(event.timeRange.start)} – '
        '${_formatDateTime(event.timeRange.end)}';
    if (event.location.isEmpty) return range;
    return '$range · ${event.location}';
  }

  String _formatDateTime(DateTime dt) {
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Future<void> _archiveEvent(BuildContext context, Event event) async {
    final result = await widget.viewModel.archiveEvent(event.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _deleteEvent(BuildContext context, Event event) async {
    final result = await widget.viewModel.deleteEvent(event.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _openEventForm(BuildContext context, {Event? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final locationController =
        TextEditingController(text: existing?.location ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');

    final now = DateTime.now();
    var start = existing?.timeRange.start ?? now;
    var end = existing?.timeRange.end ?? now.add(const Duration(hours: 1));

    return showAppInputSurface(
      context,
      title: existing == null ? 'Add Event' : 'Edit Event',
      onSave: () => _saveEventForm(
        context,
        existing: existing,
        titleController: titleController,
        locationController: locationController,
        descriptionController: descriptionController,
        start: () => start,
        end: () => end,
      ),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(label: 'Title', controller: titleController, autofocus: true),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Starts'),
              subtitle: Text(_formatDateTime(start)),
              onTap: () async {
                final picked = await _pickDateTime(context, initial: start);
                if (picked != null) setState(() => start = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ends'),
              subtitle: Text(_formatDateTime(end)),
              onTap: () async {
                final picked = await _pickDateTime(context, initial: end);
                if (picked != null) setState(() => end = picked);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Location (optional)',
              controller: locationController,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Description (optional)',
              controller: descriptionController,
            ),
            if (existing != null && existing.status == EventStatus.active) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _archiveEvent(context, existing);
                  },
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    required DateTime initial,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 5),
      lastDate: DateTime(initial.year + 5),
    );
    if (date == null || !context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _saveEventForm(
    BuildContext context, {
    required Event? existing,
    required TextEditingController titleController,
    required TextEditingController locationController,
    required TextEditingController descriptionController,
    required DateTime Function() start,
    required DateTime Function() end,
  }) async {
    Navigator.of(context).pop();

    final EventTimeRange timeRange;
    try {
      timeRange = EventTimeRange(start: start(), end: end());
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.toString());
      return;
    }

    final result = existing == null
        ? await widget.viewModel.createEvent(
            title: titleController.text,
            timeRange: timeRange,
            location: locationController.text,
            description: descriptionController.text,
          )
        : await widget.viewModel.updateEvent(
            eventId: existing.id,
            title: titleController.text,
            timeRange: timeRange,
            location: locationController.text,
            description: descriptionController.text,
          );

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
