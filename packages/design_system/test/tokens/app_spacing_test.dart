import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spacing scale is a strictly increasing 4pt progression', () {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.md, 16);
    expect(AppSpacing.lg, 24);
    expect(AppSpacing.xl, 32);
    expect(AppSpacing.xxl, 48);
    expect(
      [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ],
      orderedEquals(
        [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ]..sort(),
      ),
    );
  });
}
