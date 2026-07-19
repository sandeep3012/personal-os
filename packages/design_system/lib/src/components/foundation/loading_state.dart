import 'package:design_system/src/components/foundation/skeleton_list.dart';
import 'package:flutter/material.dart';

/// The app-wide full-screen (or section) loading indicator.
///
/// [skeleton] renders [SkeletonList] instead of a spinner — use it when the
/// eventual content's row shape is known, so the transition into content
/// feels less like a hard cut (VPS §4).
final class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.skeleton = false,
    this.skeletonRowCount = 6,
  });

  final bool skeleton;
  final int skeletonRowCount;

  @override
  Widget build(BuildContext context) {
    if (skeleton) return SkeletonList(rowCount: skeletonRowCount);
    return Center(
      child: Semantics(
        label: 'Loading',
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
