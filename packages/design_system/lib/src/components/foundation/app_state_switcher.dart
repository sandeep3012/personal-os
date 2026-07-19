import 'package:application/application.dart' show AsyncState;
import 'package:design_system/src/components/foundation/empty_state.dart';
import 'package:design_system/src/components/foundation/error_state.dart';
import 'package:design_system/src/components/foundation/loading_state.dart';
import 'package:design_system/src/tokens/app_motion.dart';
import 'package:flutter/material.dart';

/// The single mechanism every screen's body uses to render an
/// [AsyncState] — the one place that guarantees no screen ever hard-cuts
/// between Loading/Empty/Error/Success (VPS §1.6, TIS §3).
///
/// [isEmpty], when supplied, is checked on a successful [state] to decide
/// between [emptyBuilder] and [successBuilder] — most lists need this;
/// screens whose success data is never "empty" in a user-facing sense can
/// omit it.
final class AppStateSwitcher<T> extends StatelessWidget {
  const AppStateSwitcher({
    super.key,
    required this.state,
    required this.successBuilder,
    this.isEmpty,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.loadingSkeleton = false,
    this.onRetry,
  });

  final AsyncState<T> state;
  final Widget Function(BuildContext context, T data) successBuilder;
  final bool Function(T data)? isEmpty;

  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  final bool loadingSkeleton;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final child = state.when(
      loading: () => LoadingState(skeleton: loadingSkeleton),
      success: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          return EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          );
        }
        return successBuilder(context, data);
      },
      error: (error) => ErrorState(message: error.message, onRetry: onRetry),
    );

    return AnimatedSwitcher(
      duration: AppMotion.durationOrZero(context, AppMotion.standard),
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: AppMotion.decelerateCurve,
      child: KeyedSubtree(
        key: ValueKey(state.runtimeType),
        child: child,
      ),
    );
  }
}
