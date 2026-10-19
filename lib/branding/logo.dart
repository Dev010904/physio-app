import 'dart:math' as math;

import 'package:flutter/material.dart';

/// PhysioSathi mark: two arcs moving together. The outer arc echoes the
/// session ring patients see every day; the inner arc is the companion
/// ("sathi") moving alongside; the dot is the step forward.
class LogoPainter extends CustomPainter {
  const LogoPainter({
    required this.outer,
    required this.inner,
    this.background,
    this.scale = 1,
  });

  /// Full-colour mark on the brand teal tile.
  const LogoPainter.tile()
    : outer = Colors.white,
      inner = const Color(0xFF9FE1CB),
      background = const Color(0xFF0F6E56),
      scale = 1;

  final Color outer;
  final Color inner;

  /// Rounded-square tile behind the mark; null draws the mark alone.
  final Color? background;

  /// Shrinks the mark inside its box, e.g. to fit an adaptive icon's safe zone.
  final double scale;

  static const _deg = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    if (background != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.23)),
        Paint()..color = background!,
      );
    }
    final m = s * scale;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = m * 0.085;

    // Outer arc: three quarters of a ring, open at the upper left.
    final rOuter = m * 0.30;
    canvas.drawArc(Rect.fromCircle(center: c, radius: rOuter), -60 * _deg, 270 * _deg, false,
        stroke..color = outer);

    // Inner arc: the companion, turning with it.
    final rInner = m * 0.155;
    canvas.drawArc(Rect.fromCircle(center: c, radius: rInner), 120 * _deg, 220 * _deg, false,
        stroke..color = inner);

    // The step forward, sitting in the outer arc's gap.
    final dotAngle = -105 * _deg;
    canvas.drawCircle(
      c + Offset(math.cos(dotAngle), math.sin(dotAngle)) * rOuter,
      m * 0.062,
      Paint()..color = inner,
    );
  }

  @override
  bool shouldRepaint(LogoPainter old) =>
      old.outer != outer || old.inner != inner || old.background != background || old.scale != scale;
}

/// The logo tile at any size.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const LogoPainter.tile());
}

/// Logo tile plus the "PhysioSathi" wordmark.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: size * 0.8, fontWeight: FontWeight.w700, letterSpacing: -0.3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: size),
        SizedBox(width: size * 0.35),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Physio', style: style.copyWith(color: colors.onSurface)),
            TextSpan(text: 'Sathi', style: style.copyWith(color: colors.primary)),
          ]),
        ),
      ],
    );
  }
}
