import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/generic_tile.dart';
import 'transactions_screen.dart';

/// DOC-034 Part B §4.4 — Account Details detail page.
class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key, required this.account});

  final FakeAccount account;

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recent = FakeData.transactions.where((t) => t.account == account.name).take(2).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
        children: [
          Center(
            child: Column(
              children: [
                Text('₹${account.balance.abs().toStringAsFixed(0)}', style: textTheme.headlineMedium),
                Text('Current Balance', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const SizedBox(
                    height: 90,
                    child: CustomPaint(painter: _MiniTrendPainter(), size: Size.infinite),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text('Jan', style: TextStyle(fontSize: 11)),
                      Text('Feb', style: TextStyle(fontSize: 11)),
                      Text('Mar', style: TextStyle(fontSize: 11)),
                      Text('Apr', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Recent Activity', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final t in recent)
            GenericTile(
              icon: t.icon,
              iconColor: semantic.moduleAccent('finance'),
              title: t.title,
              trailing: '${t.amount < 0 ? '−' : '+'}₹${t.amount.abs().toStringAsFixed(0)}',
              trailingColor: t.amount < 0 ? null : semantic.positive,
            ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
              ),
              child: const Text('See all →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  const _MiniTrendPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.2, size.width * 0.3, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.8, size.width * 0.6, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.1, size.width, size.height * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
