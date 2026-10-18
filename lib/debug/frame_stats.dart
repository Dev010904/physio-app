import 'dart:ui';

import 'package:flutter/scheduler.dart';

/// Logs frame timings in dev builds so smoothness is measured, not guessed.
///
/// Every [every] of rendering it prints one line to the device log, e.g.
/// `[frames] 600 frames @120Hz (8.3 ms budget) build p95 1.2 ms · raster p95 3.4 ms · janky 0.5%`.
abstract final class FrameStats {
  static void start({Duration every = const Duration(seconds: 5)}) {
    final timings = <FrameTiming>[];
    var windowStart = DateTime.now();

    SchedulerBinding.instance.addTimingsCallback((batch) {
      timings.addAll(batch);
      if (DateTime.now().difference(windowStart) < every) return;
      windowStart = DateTime.now();

      final views = PlatformDispatcher.instance.views;
      final hz = views.isEmpty ? 60.0 : views.first.display.refreshRate;
      final budgetUs = 1e6 / hz;
      final build = [for (final t in timings) t.buildDuration.inMicroseconds]..sort();
      final raster = [for (final t in timings) t.rasterDuration.inMicroseconds]..sort();
      // What the eye sees: during continuous animation every refresh should
      // get a new frame, so a gap longer than 1.5 refreshes is a dropped frame.
      // (Raster time alone overstates jank: it can include waiting for vsync.)
      final vsyncs = [
        for (final t in timings) t.timestampInMicroseconds(FramePhase.vsyncStart),
      ]..sort();
      var dropped = 0;
      for (var i = 1; i < vsyncs.length; i++) {
        if (vsyncs[i] - vsyncs[i - 1] > 1.5 * budgetUs) dropped++;
      }
      final spanUs = vsyncs.last - vsyncs.first;
      final fps = spanUs > 0 ? (vsyncs.length - 1) * 1e6 / spanUs : 0;

      String ms(int us) => (us / 1000).toStringAsFixed(1);
      int p95(List<int> sorted) => sorted[((sorted.length - 1) * 0.95).round()];

      // Plain print: in profile/release builds Sentry turns debugPrint into
      // breadcrumbs and nothing reaches the device log.
      // ignore: avoid_print
      print(
        '[frames] ${timings.length} frames, ${fps.toStringAsFixed(0)} fps on a ${hz.round()} Hz screen, '
        'dropped ${(100 * dropped / timings.length).toStringAsFixed(1)}% · '
        'build p95 ${ms(p95(build))} ms · raster p95 ${ms(p95(raster))} ms, worst ${ms(raster.last)} ms',
      );
      timings.clear();
    });
  }
}
