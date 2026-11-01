import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Greeting header: avatar, "Good morning", name, square action button.
class GreetingHeader extends StatelessWidget {
  final String name;
  final VoidCallback onAction;
  final IconData actionIcon;
  const GreetingHeader({
    super.key,
    required this.name,
    required this.onAction,
    this.actionIcon = Icons.grid_view_rounded,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Avatar(name: name, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting, style: AppText.small),
              const SizedBox(height: 2),
              Text(name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            ],
          ),
        ),
        SquareIconButton(icon: actionIcon, onTap: onAction),
      ],
    );
  }
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  const Avatar({super.key, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF7B5CFF), Color(0xFF2A1B6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.42),
      ),
    );
  }
}

class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
              width: 44, height: 44, child: Icon(icon, color: foreground, size: 22)),
        ),
      );
}

/// Big filled blue circle with an icon, value and label (hero stat).
class HeroCircle extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final double progress; // 0..1, drawn as a thin white arc
  final double size;
  final Color color;
  const HeroCircle({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.progress,
    this.size = 150,
    this.color = AppColors.violet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12)),
        ],
      ),
      child: CustomPaint(
        painter: _ArcPainter(progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
              ),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  _ArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(9);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false,
        p..color = Colors.white.withValues(alpha: 0.18));
    final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(r, -math.pi / 2, sweep, false, p..color = AppColors.lime);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

enum TileStyle { dark, light, violet, lime }

/// Rounded dashboard tile (black / white / blue) with a title, a visual and
/// a big value at the bottom, like a fitness-app activity card.
class MetricTile extends StatelessWidget {
  final TileStyle style;
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Widget? visual;
  final VoidCallback? onTap;
  final double height;
  final Widget? footer;

  const MetricTile({
    super.key,
    required this.style,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    this.visual,
    this.onTap,
    this.height = 178,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (style) {
      TileStyle.dark => AppColors.ink,
      TileStyle.light => AppColors.surface,
      TileStyle.violet => AppColors.violet,
      TileStyle.lime => AppColors.lime,
    };
    final fg = (style == TileStyle.light || style == TileStyle.lime)
        ? AppColors.ink
        : Colors.white;
    final iconColor = switch (style) {
      TileStyle.dark => AppColors.lime,
      TileStyle.light => AppColors.violet,
      TileStyle.violet => AppColors.lime,
      TileStyle.lime => AppColors.ink,
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: visual ?? const SizedBox.shrink(),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value,
                        style: TextStyle(
                            color: fg,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(unit,
                          style: TextStyle(
                              color: fg.withValues(alpha: 0.7), fontSize: 12)),
                    ),
                    const Spacer(),
                    if (footer != null) footer!,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded row: label on the left, big value + unit on the right.
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Widget? leading;
  final VoidCallback? onTap;
  final Color? valueColor;
  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.leading,
    this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                Text(value,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: valueColor ?? AppColors.ink,
                        letterSpacing: -0.4)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(unit, style: AppText.small),
                ],
              ]),
            ),
          ),
        ),
      );
}

/// Big bold section title with an optional trailing widget.
class BigTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const BigTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 26, 2, 14),
        child: Row(children: [
          Expanded(child: Text(text, style: AppText.h1)),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Small black pill button, e.g. "+ Log food".
class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool light;
  const PillButton(
      {super.key, required this.label, required this.onTap, this.icon, this.light = false});

  @override
  Widget build(BuildContext context) => Material(
        color: light ? AppColors.surface : AppColors.ink,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: light ? AppColors.ink : Colors.white),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      color: light ? AppColors.ink : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ]),
          ),
        ),
      );
}

/// Round black floating action circle (like the "Exercise" bubble).
class CircleAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const CircleAction(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap,
      this.size = 86});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.ink,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}

/// Pill-shaped segmented selector with a black selected state.
class PillSelector<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const PillSelector({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: values.map((v) {
            final sel = v == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(label(v),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: sel ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

/// Square icon badge with a tinted background.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge(
      {super.key, required this.icon, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}
