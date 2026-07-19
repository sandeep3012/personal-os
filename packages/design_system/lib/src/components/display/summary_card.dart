import 'package:design_system/src/components/display/module_card_base.dart';
import 'package:flutter/material.dart';

/// A static, non-navigable information card used *within* a module (e.g.
/// Finance Dashboard's own summary block) — the lighter sibling of
/// [ModuleCard], which additionally navigates and handles [AsyncState]
/// (VPS §2).
final class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return ModuleCardBase(
      icon: icon,
      accentColor: accentColor,
      title: title,
      body: body,
    );
  }
}
