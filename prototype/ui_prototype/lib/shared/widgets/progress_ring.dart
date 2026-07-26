import 'package:flutter/material.dart';

/// DOC-034 Part O — ring progress indicator (Apple-Health-style summary).
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({super.key, required this.value, required this.color, this.size = 64, this.label});

  final double value;
  final Color color;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(track),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (label != null)
            Text(label!, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
