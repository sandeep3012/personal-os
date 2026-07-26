import 'package:flutter/material.dart';

import '../../design/tokens/app_icon_sizes.dart' show AppIconSizes;

/// Small tinted-circle icon used for a module's identity mark on Home/More
/// cards and list-row leading icons (DOC-033 §2.4 — the "one legitimate
/// place per row" for a module accent color).
class ModuleIcon extends StatelessWidget {
  const ModuleIcon({super.key, required this.icon, required this.color, this.size = AppIconSizes.avatar});

  final String icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(icon, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
