import 'package:flutter/material.dart';

/// DOC-034 Part O — linear progress bar (Habits/Goals cards).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.outlineVariant;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
