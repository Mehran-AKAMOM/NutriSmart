import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A retro "hunger bar" made of pixel-art drumsticks, used for protein.
/// Each of the [count] drumsticks is worth 1/[count] of the daily target and
/// fills in halves, like a classic video-game food meter.
class DrumstickMeter extends StatelessWidget {
  final double progress; // 0..1+ (share of the protein target eaten)
  final int count;
  final int perRow;
  const DrumstickMeter({
    super.key,
    required this.progress,
    this.count = 10,
    this.perRow = 5,
  });

  @override
  Widget build(BuildContext context) {
    // Number of half-drumsticks earned, e.g. 0.37 of target -> 7 halves.
    final halves = (progress.clamp(0.0, 1.0) * count * 2).floor();
    final rows = (count / perRow).ceil();
    return LayoutBuilder(builder: (context, c) {
      const gap = 4.0;
      final size = math.min(
        (c.maxWidth - gap * (perRow - 1)) / perRow,
        (c.maxHeight - gap * (rows - 1)) / rows,
      ).floorToDouble();
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (r) {
            return Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(perRow, (i) {
                  final index = r * perRow + i;
                  final fill = index * 2 + 2 <= halves
                      ? _Fill.full
                      : index * 2 + 1 <= halves
                          ? _Fill.half
                          : _Fill.empty;
                  return Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
                    child: CustomPaint(
                      size: Size.square(size),
                      painter: _DrumstickPainter(fill),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      );
    });
  }
}

enum _Fill { full, half, empty }

/// 10x10 pixel sprite (our own design).
///   o outline, h highlight, m meat, d meat shadow, b bone, s bone shadow
const _sprite = [
  '..ooo.....',
  '.ohhmo....',
  'ohhmmmo...',
  'ohmmmmo...',
  'ommmmdo...',
  '.ommddoo..',
  '..oooobooo',
  '.....obsbo',
  '......obbo',
  '.......oo.',
];

const _colors = {
  'o': Color(0xFF3A1C0C),
  'h': Color(0xFFF2A15C),
  'm': Color(0xFFD06A2A),
  'd': Color(0xFF9A4718),
  'b': Color(0xFFF4EEDF),
  's': Color(0xFFCFC5B2),
};

// Colours for an empty (not yet earned) drumstick: a dark silhouette.
const _emptyOutline = Color(0xFF34313D);
const _emptyFill = Color(0xFF23212A);

class _DrumstickPainter extends CustomPainter {
  final _Fill fill;
  _DrumstickPainter(this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 10;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < 10; y++) {
      final row = _sprite[y];
      for (var x = 0; x < 10; x++) {
        final ch = row[x];
        if (ch == '.') continue;
        // A half drumstick shows the left half in colour.
        final lit = fill == _Fill.full || (fill == _Fill.half && x < 5);
        paint.color = lit
            ? _colors[ch]!
            : (ch == 'o' ? _emptyOutline : _emptyFill);
        canvas.drawRect(
          Rect.fromLTWH(x * px, y * px, px + 0.5, px + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DrumstickPainter old) => old.fill != fill;
}
