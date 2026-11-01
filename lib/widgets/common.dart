import 'package:flutter/material.dart';

import '../services/insights.dart';
import '../theme.dart';
import 'ui.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
        child: Row(
          children: [
            Text(text, style: AppText.h2),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class InsightCard extends StatelessWidget {
  final Insight insight;
  const InsightCard(this.insight, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.kind) {
      InsightKind.good => AppColors.limeDark,
      InsightKind.warning => AppColors.danger,
      InsightKind.tip => AppColors.violet,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: insight.icon, color: color, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(insight.message, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded tile showing a value + label (e.g. "32 g  Protein").
class StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool filled;
  const StatPill({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.4,
                    color: filled ? Colors.white : color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: filled ? Colors.white70 : AppColors.muted)),
          ],
        ),
      );
}

String fmt(double v, {int decimals = 0}) =>
    v.toStringAsFixed(v.abs() >= 10 ? 0 : decimals);
