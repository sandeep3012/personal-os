import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';

/// DOC-034 §13 — shimmer-toned skeleton rows previewing the shape of
/// content about to appear. Used for list/grid first loads.
class LoadingSkeletonList extends StatefulWidget {
  const LoadingSkeletonList({super.key, this.rows = 4});

  final int rows;

  @override
  State<LoadingSkeletonList> createState() => _LoadingSkeletonListState();
}

class _LoadingSkeletonListState extends State<LoadingSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlight = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(base, highlight, _controller.value)!;
        return Column(
          children: List.generate(widget.rows, (i) => _skeletonCard(color)),
        );
      },
    );
  }

  Widget _skeletonCard(Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _bar(color, width: 40, height: 40, radius: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(color, width: 140, height: 14),
                    const SizedBox(height: AppSpacing.xs),
                    _bar(color, width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _bar(Color color, {required double width, required double height, double radius = 4}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      );
}

/// Compact spinner used inside a card's loading slot or an in-flight action
/// — never for a full list (DOC-033 §13).
class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
}
