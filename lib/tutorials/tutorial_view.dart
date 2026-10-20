import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../common/ui.dart';
import '../exercises/exercise.dart';
import 'tutorial.dart';

/// Shows [tutorial]'s footage at the position [progress] returns
/// (0 = start pose, 1 = end pose), repainting whenever [repaint] fires, so a
/// session can drive it frame by frame without rebuilding.
class TutorialFrames extends StatefulWidget {
  const TutorialFrames({super.key, required this.tutorial, required this.progress, required this.repaint});

  final Tutorial tutorial;
  final double Function() progress;
  final Listenable repaint;

  @override
  State<TutorialFrames> createState() => _TutorialFramesState();
}

class _TutorialFramesState extends State<TutorialFrames> {
  ImageStream? _stream;
  ImageInfo? _sheet;
  late final _listener = ImageStreamListener(
    (info, _) {
      if (!mounted) return info.dispose();
      setState(() {
        _sheet?.dispose();
        _sheet = info;
      });
    },
    // A missing sheet leaves the soft background; the steps still explain it.
    onError: (_, _) {},
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(TutorialFrames old) {
    super.didUpdateWidget(old);
    if (old.tutorial.sheet != widget.tutorial.sheet) _resolve();
  }

  void _resolve() {
    final stream = AssetImage(widget.tutorial.sheet).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _sheet?.dispose();
    _sheet = null;
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _sheet?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _sheet?.image;
    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: sheet == null ? 0 : 1,
        duration: const Duration(milliseconds: 250),
        child: sheet == null
            ? const SizedBox.expand()
            : CustomPaint(
                painter: TutorialPainter(
                  sheet: sheet,
                  frames: widget.tutorial.frames,
                  progress: widget.progress,
                  repaint: widget.repaint,
                ),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

/// Paints one square frame of a tutorial sheet, blending into the next frame
/// by how far between the two the progress is. That keeps motion smooth at
/// any refresh rate, not just the footage's own 16 frames a second.
class TutorialPainter extends CustomPainter {
  TutorialPainter({required this.sheet, required this.frames, required this.progress, super.repaint});

  final ui.Image sheet;
  final int frames;
  final double Function() progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = (frames + Tutorial.columns - 1) ~/ Tutorial.columns;
    final cell = sheet.height / rows;
    final position = progress().clamp(0.0, 1.0) * (frames - 1);
    final i = position.floor().clamp(0, frames - 1);
    final blend = position - i;

    final side = size.shortestSide;
    final dst = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(sheet, _cell(i, cell), dst, paint);
    if (blend > 0.01 && i + 1 < frames) {
      canvas.drawImageRect(sheet, _cell(i + 1, cell), dst, paint..color = Color.fromRGBO(0, 0, 0, blend));
    }
  }

  // Half a pixel in from each edge so filtering never picks up the next frame.
  static Rect _cell(int i, double cell) =>
      Rect.fromLTWH((i % Tutorial.columns) * cell + 0.5, (i ~/ Tutorial.columns) * cell + 0.5, cell - 1, cell - 1);

  @override
  bool shouldRepaint(TutorialPainter old) => old.sheet != sheet || old.frames != frames;
}

/// Looping demonstration: move, hold, return and pause, over [cycle].
/// With reduced motion turned on in the phone, it rests on the end pose.
class TutorialLoop extends StatefulWidget {
  const TutorialLoop({super.key, required this.tutorial, this.cycle = const Duration(seconds: 5)});

  /// Paces the loop from the exercise's own tempo.
  factory TutorialLoop.forExercise(Tutorial tutorial, Exercise exercise, {Key? key}) {
    final rx = exercise.prescription;
    // Move and return take 70% of the loop.
    final seconds = rx.isTimed ? 3.0 : ((rx.moveSeconds + rx.releaseSeconds) / 0.7).clamp(3.0, 9.0);
    return TutorialLoop(
      key: key,
      tutorial: tutorial,
      cycle: Duration(milliseconds: (seconds * 1000).round()),
    );
  }

  final Tutorial tutorial;
  final Duration cycle;

  @override
  State<TutorialLoop> createState() => _TutorialLoopState();
}

class _TutorialLoopState extends State<TutorialLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: widget.cycle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.value = widget.tutorial.sway ? 0.5 : 0.45;
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TutorialFrames(
    tutorial: widget.tutorial,
    progress: () => demoProgress(_loop.value, widget.tutorial),
    repaint: _loop,
  );
}

/// Small still of the exercise at its working position, muscles lit.
class TutorialThumb extends StatelessWidget {
  const TutorialThumb({super.key, required this.exercise, this.size = 56});

  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tutorial = tutorials[exercise.id];
    if (tutorial == null) return IconBadge(region: exercise.bodyRegion, size: size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: Image.asset(
        tutorial.poster,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        excludeFromSemantics: true,
      ),
    );
  }
}

/// "What it does": muscles grouped by effect, each with its glow colour.
class MuscleLegend extends StatelessWidget {
  const MuscleLegend({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final tutorial = tutorials[exercise.id];
    if (tutorial == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final MapEntry(key: effect, value: names) in tutorial.muscles.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 5), child: EffectDot(effect)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${effect.label}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: names.join(', ')),
                      ],
                    ),
                    style: text.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The glow colour of an [Effect], as a dot with a soft halo like the footage.
class EffectDot extends StatelessWidget {
  const EffectDot(this.effect, {super.key, this.size = 14});

  final Effect effect;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: effect.color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: effect.color.withValues(alpha: 0.5), blurRadius: size * 0.5)],
    ),
  );
}
