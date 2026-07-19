import 'package:design_system/src/tokens/app_motion.dart';
import 'package:design_system/src/tokens/app_radius.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A shimmering placeholder list matching a real row's shape, shown while
/// content is loading (VPS §4 "Loading states").
///
/// The shimmer sweep is a single, repeating [AnimationController] — a
/// legitimate long-lived animation, not a one-shot micro-interaction — and
/// is skipped entirely (static placeholder color) when the platform's
/// reduced-motion setting is enabled.
final class SkeletonList extends StatefulWidget {
  const SkeletonList({
    super.key,
    this.rowCount = 6,
    this.rowHeight = 56,
  });

  final int rowCount;
  final double rowHeight;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.page * 3,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (reducedMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final highlight = scheme.surfaceContainerHighest;

    return Semantics(
      label: 'Loading content',
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: widget.rowCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (reducedMotion) {
            return _SkeletonRow(height: widget.rowHeight, color: base);
          }
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _SkeletonRow(
              height: widget.rowHeight,
              color: Color.lerp(base, highlight, _controller.value)!,
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}
