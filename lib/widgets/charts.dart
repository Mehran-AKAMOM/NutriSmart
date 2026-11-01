import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Labelled horizontal progress bar ("Protein   42 / 120 g").
class NutrientBar extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;
  final bool isLimit; // e.g. sugar/sodium: going over is bad

  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    this.isLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target <= 0 ? 0.0 : value / target;
    final over = isLimit ? pct > 1 : pct > 1.15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: AppText.label),
            const Spacer(),
            Text('${value.round()}',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: over ? AppColors.danger : AppColors.ink)),
            Text(' / ${target.round()} $unit', style: AppText.small),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 8,
            color: over ? AppColors.danger : color,
            backgroundColor: AppColors.line,
          ),
        ),
      ],
    );
  }
}

/// Pulse-style line (used on the black protein tile).
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const Sparkline({super.key, required this.values, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _SparkPainter(values, color));
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - minV) / range * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}

/// A heartbeat-like pulse whose spike height follows [level] (0..1).
List<double> pulseShape(double level) {
  final l = level.clamp(0.08, 1.0);
  return [
    0.5, 0.5, 0.5, 0.52, 0.48, 0.5, 0.5,
    0.5 + 0.12 * l, 0.5 - 0.1 * l, 0.5 + 0.5 * l, 0.5 - 0.45 * l, 0.5 + 0.08 * l,
    0.5, 0.5, 0.52, 0.48, 0.5, 0.5,
    0.5 + 0.1 * l, 0.5 - 0.08 * l, 0.5 + 0.35 * l, 0.5 - 0.3 * l, 0.5,
    0.5, 0.5, 0.5,
  ];
}

/// Smooth wave whose amplitude grows with [level] (used on the water tile).
class WaveVisual extends StatelessWidget {
  final double level; // 0..1
  final Color color;
  const WaveVisual({super.key, required this.level, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _WavePainter(level, color));
}

class _WavePainter extends CustomPainter {
  final double level;
  final Color color;
  _WavePainter(this.level, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final amp = size.height * (0.12 + 0.33 * level.clamp(0.0, 1.0));
    final mid = size.height / 2;
    final path = Path()..moveTo(0, mid);
    for (double x = 0; x <= size.width; x += 2) {
      path.lineTo(x, mid + math.sin(x / size.width * math.pi * 4) * amp);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.level != level;
}

/// Thin vertical bars (used on the blue meals tile).
class TickBars extends StatelessWidget {
  final List<double> values;
  final Color color;
  const TickBars({super.key, required this.values, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _TickPainter(values, color));
}

class _TickPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _TickPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = math.max(values.reduce(math.max), 1.0);
    final gap = size.width / values.length;
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < values.length; i++) {
      final h = math.max(4.0, size.height * values[i] / maxV);
      final x = gap * i + gap / 2;
      canvas.drawLine(Offset(x, size.height / 2 - h / 2),
          Offset(x, size.height / 2 + h / 2), p);
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => true;
}

/// Week strip: day labels over a row of fine ticks with a bar per day.
class WeekStrip extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final double target;
  final int highlight; // index to colour blue (today)
  const WeekStrip({
    super.key,
    required this.labels,
    required this.values,
    required this.target,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(
            labels.length,
            (i) => Expanded(
              child: Text(labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == highlight ? FontWeight.w800 : FontWeight.w500,
                      color: i == highlight ? AppColors.ink : AppColors.muted)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: CustomPaint(
            size: Size.infinite,
            painter: _WeekPainter(values, target, highlight),
          ),
        ),
      ],
    );
  }
}

class _WeekPainter extends CustomPainter {
  final List<double> values;
  final double target;
  final int highlight;
  _WeekPainter(this.values, this.target, this.highlight);

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final slot = size.width / n;
    final tick = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.4;
    for (double x = 2; x < size.width; x += 5) {
      canvas.drawLine(Offset(x, size.height - 8), Offset(x, size.height), tick);
    }
    final maxV = math.max(target, values.fold<double>(0, math.max)) * 1.05;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final h = (size.height - 10) * (v / maxV);
      final x = slot * i + slot / 2;
      canvas.drawLine(
        Offset(x, size.height - 2),
        Offset(x, size.height - 2 - h),
        Paint()
          ..color = i == highlight ? AppColors.violet : AppColors.ink
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WeekPainter old) => true;
}

/// Big red bar chart with a right-hand axis (Progress screen).
class BigBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double? target;
  final double height;
  const BigBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.target,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _BigBarPainter(values, labels, target),
        ),
      );
}

class _BigBarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double? target;
  _BigBarPainter(this.values, this.labels, this.target);

  void _text(Canvas c, String s, Offset o, {bool center = true, double size = 11}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s, style: TextStyle(fontSize: size, color: AppColors.muted)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o - Offset(center ? tp.width / 2 : 0, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const axisW = 40.0, labelH = 22.0;
    final w = size.width - axisW;
    final h = size.height - labelH;
    final maxRaw = math.max(values.fold<double>(0, math.max), target ?? 0);
    final step = maxRaw <= 0 ? 500.0 : (maxRaw / 4 / 100).ceil() * 100.0;
    final maxV = step * 4;

    // Grid + axis labels
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = h - h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
      _text(canvas, (step * i).round().toString(), Offset(w + 8, y), center: false);
    }

    final slot = w / values.length;
    for (var i = 0; i < values.length; i++) {
      final x = slot * i + slot / 2;
      final v = values[i];
      if (v > 0) {
        final top = h - h * (v / maxV);
        final over = target != null && v > target! * 1.1;
        canvas.drawLine(
          Offset(x, h - 2),
          Offset(x, top),
          Paint()
            ..color = over ? AppColors.ink : AppColors.violet
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(Offset(x, h - 4), 3, Paint()..color = AppColors.line);
      }
      _text(canvas, labels[i], Offset(x, h + labelH / 2 + 2));
    }

    if (target != null && target! > 0) {
      final y = h - h * (target! / maxV);
      final p = Paint()
        ..color = AppColors.limeDark
        ..strokeWidth = 2;
      for (double x = 0; x < w; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, w), y), p);
      }
    }
  }

  @override
  bool shouldRepaint(_BigBarPainter old) => true;
}

/// Simple line chart (body weight).
class SimpleLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;

  const SimpleLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = AppColors.violet,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _LinePainter(values, labels, color),
        ),
      );
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  _LinePainter(this.values, this.labels, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelH = 20.0, rightPad = 40.0;
    final chartH = size.height - labelH;
    final w = size.width - rightPad;
    var minV = values.reduce(math.min), maxV = values.reduce(math.max);
    if (maxV - minV < 2) {
      minV -= 1;
      maxV += 1;
    }
    double yOf(double v) =>
        chartH - (v - minV) / (maxV - minV) * (chartH - 16) - 8;
    double xOf(int i) => values.length == 1 ? w / 2 : 8 + (w - 16) * i / (values.length - 1);

    void text(String s, Offset o) {
      final tp = TextPainter(
        text: TextSpan(
            text: s, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }

    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (final v in [minV, (minV + maxV) / 2, maxV]) {
      canvas.drawLine(Offset(0, yOf(v)), Offset(w, yOf(v)), grid);
      text(v.toStringAsFixed(1), Offset(w + 20, yOf(v)));
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final o = Offset(xOf(i), yOf(values[i]));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < values.length; i++) {
      final o = Offset(xOf(i), yOf(values[i]));
      canvas.drawCircle(o, 6, Paint()..color = Colors.white);
      canvas.drawCircle(o, 4, Paint()..color = color);
    }
    text(labels.first, Offset(xOf(0), chartH + labelH / 2));
    if (values.length > 1) {
      text(labels.last, Offset(xOf(values.length - 1), chartH + labelH / 2));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}
