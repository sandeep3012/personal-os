import 'package:application/application.dart' show AsyncState;
import 'package:design_system/src/components/display/module_card_base.dart';
import 'package:flutter/material.dart';

/// The Home-screen summary card shape every module (present or future)
/// renders through (TIS §5 "Card registration") — icon+accent, title, a
/// small amount of key stats, trailing chevron when tappable.
///
/// Renders [state] per-card, independently of any other `ModuleCard` on
/// the same screen — one module's [AsyncState.error] never blanks another
/// module's card (TIS §5 "Loading / Error isolation").
final class ModuleCard<T> extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.state,
    required this.contentBuilder,
    this.onTap,
    this.loadingHeight = 48,
    this.errorMessage,
    this.semanticLabel,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final AsyncState<T> state;
  final Widget Function(BuildContext context, T data) contentBuilder;
  final VoidCallback? onTap;

  /// Height reserved for the loading placeholder, keeping card height
  /// stable across state transitions.
  final double loadingHeight;

  /// Overrides the message shown when [state] is an error. Defaults to a
  /// generic "Couldn't load {title}".
  final String? errorMessage;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return ModuleCardBase(
      icon: icon,
      accentColor: accentColor,
      title: title,
      onTap: onTap,
      semanticLabel: semanticLabel,
      body: state.when(
        loading: () => SizedBox(
          height: loadingHeight,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        success: (data) => contentBuilder(context, data),
        error: (error) => Text(
          errorMessage ?? "Couldn't load $title",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    );
  }
}
