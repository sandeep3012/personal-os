import 'package:decimal/decimal.dart';
import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// How a [MoneyText] amount relates to its semantic meaning — never the
/// only signal (VPS §1.8): the sign prefix always renders alongside color.
enum MoneySemantic {
  /// No special coloring (e.g. a balance figure).
  none,

  /// Rendered in [AppSemanticColors.positive].
  positive,

  /// Rendered in [AppSemanticColors.negative].
  negative,
}

/// Text-size variants for [MoneyText] (VPS §1.2 "Money" role).
enum MoneyTextVariant { display, title, body }

/// The single formatting call site for currency amounts anywhere in the
/// app (TIS §3) — no screen formats money manually.
///
/// Accepts a plain [Decimal] and a currency code string — never a feature's
/// `Money` value object — so this component has no dependency on any
/// feature package.
final class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.signed = false,
    this.semantic = MoneySemantic.none,
    this.variant = MoneyTextVariant.body,
  });

  final Decimal amount;
  final String currencyCode;
  final bool signed;
  final MoneySemantic semantic;
  final MoneyTextVariant variant;

  /// Groups the integer part Indian-style (last 3 digits, then pairs of 2
  /// from there leftward — e.g. `1,24,500`) and keeps up to two fractional
  /// digits. Full locale-aware currency formatting (respecting a
  /// non-Indian grouping convention per currency/locale) is a future
  /// refinement; this is sufficient for a single-currency-per-figure
  /// display today.
  static String format(Decimal amount, String currencyCode, {bool signed = false}) {
    final isNegative = amount.signum < 0;
    final absAmount = amount.abs();
    final fixed = absAmount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final wholePart = parts[0];
    final fractionPart = parts.length > 1 ? parts[1] : '00';

    final sign = isNegative ? '-' : (signed ? '+' : '');
    return '$sign$currencyCode ${_groupIndian(wholePart)}.$fractionPart';
  }

  static String _groupIndian(String whole) {
    if (whole.length <= 3) return whole;

    final lastThree = whole.substring(whole.length - 3);
    var remaining = whole.substring(0, whole.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);

    return '${groups.join(',')},$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();

    final style = switch (variant) {
      MoneyTextVariant.display => theme.textTheme.headlineSmall,
      MoneyTextVariant.title => theme.textTheme.titleLarge,
      MoneyTextVariant.body => theme.textTheme.bodyLarge,
    };

    final color = switch (semantic) {
      MoneySemantic.none => null,
      MoneySemantic.positive => semanticColors?.positive,
      MoneySemantic.negative => semanticColors?.negative,
    };

    final formatted = format(amount, currencyCode, signed: signed);

    return Text(
      formatted,
      style: style?.copyWith(color: color),
      semanticsLabel: _spokenForm(formatted),
    );
  }

  String _spokenForm(String formatted) {
    return formatted.replaceAll('-', 'minus ').replaceAll('+', 'plus ');
  }
}
