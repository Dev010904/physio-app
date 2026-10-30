import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/text.dart';

/// Pain (0 to 10) over a date range: a light line with a dot per score.
/// Scores of 7 and above sit in a tinted band and get a red dot.
class PainChart extends StatelessWidget {
  const PainChart({super.key, required this.points, required this.from, required this.to, this.height = 128});

  /// Oldest first.
  final List<PainPoint> points;
  final DateTime from;
  final DateTime to;
  final double height;

  static const highPain = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final latest = points.isEmpty ? null : points.last.pain;
    final highest = points.isEmpty ? null : points.map((p) => p.pain).reduce((a, b) => a > b ? a : b);
    return Semantics(
      label: 'Pain chart with ${points.length} scores. Latest $latest out of 10, highest $highest.',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _PainPainter(
            points: points,
            from: from,
            to: to,
            line: c.primary,
            high: c.error,
            grid: c.outlineVariant,
            dotFill: c.surfaceContainerLow,
            label: theme.textTheme.bodySmall!.copyWith(color: c.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _PainPainter extends CustomPainter {
  _PainPainter({
    required this.points,
    required this.from,
    required this.to,
    required this.line,
    required this.high,
    required this.grid,
    required this.dotFill,
    required this.label,
  });

  final List<PainPoint> points;
  final DateTime from;
  final DateTime to;
  final Color line;
  final Color high;
  final Color grid;
  final Color dotFill;
  final TextStyle label;

  TextPainter _text(String s) => TextPainter(text: TextSpan(text: s, style: label), textDirection: TextDirection.ltr)..layout();

  @override
  void paint(Canvas canvas, Size size) {
    const left = 26.0, right = 10.0, top = 8.0, bottom = 22.0;
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    double y(num pain) => plot.bottom - pain / 10 * plot.height;
    final span = to.difference(from).inDays.clamp(1, 100000);
    double x(DateTime day) => plot.left + day.difference(from).inDays.clamp(0, span) / span * plot.width;

    // The high-pain band and the 0 / 5 / 10 guides.
    canvas.drawRect(Rect.fromLTRB(plot.left, y(10), plot.right, y(PainChart.highPain)), Paint()..color = high.withValues(alpha: 0.07));
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in const [0, 5, 10]) {
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), gridPaint);
      final t = _text('$v');
      t.paint(canvas, Offset(left - 8 - t.width, y(v) - t.height / 2));
    }
    final start = _text(relativeDay(from, to));
    start.paint(canvas, Offset(plot.left, plot.bottom + 5));
    final end = _text('Today');
    end.paint(canvas, Offset(plot.right - end.width, plot.bottom + 5));

    if (points.isEmpty) return;
    final offsets = [for (final p in points) Offset(x(p.day), y(p.pain))];
    if (offsets.length > 1) {
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final o in offsets.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      final area = Path.from(path)
        ..lineTo(offsets.last.dx, plot.bottom)
        ..lineTo(offsets.first.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withValues(alpha: 0.18), line.withValues(alpha: 0.0)],
          ).createShader(plot),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < offsets.length; i++) {
      final isHigh = points[i].pain >= PainChart.highPain;
      canvas.drawCircle(offsets[i], 5, Paint()..color = dotFill);
      canvas.drawCircle(
        offsets[i],
        5,
        Paint()
          ..color = isHigh ? high : line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      if (isHigh) canvas.drawCircle(offsets[i], 2.2, Paint()..color = high);
    }
  }

  @override
  bool shouldRepaint(_PainPainter old) =>
      !listEquals(old.points, points) ||
      old.from != from ||
      old.to != to ||
      old.line != line ||
      old.high != high ||
      old.grid != grid ||
      old.dotFill != dotFill ||
      old.label != label;
}
