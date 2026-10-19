// Renders the logo to PNGs in assets/branding/ for the app icon generator.
// Run from the project root: flutter test tool/render_brand_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/branding/logo.dart';

Future<void> _render(String path, LogoPainter painter, {int size = 1024}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('render brand assets', (tester) async {
    await tester.runAsync(() async {
      const dir = 'assets/branding';
      // Legacy square icon and store artwork: mark on the teal tile.
      await _render('$dir/icon_full.png', const LogoPainter.tile());
      // Adaptive icon layers: the generator insets them 16% and Android shows the
      // centre 66 of 108 dp, so 0.9 keeps the mark the same visual size as the tile.
      await _render(
        '$dir/icon_foreground.png',
        const LogoPainter(outer: Colors.white, inner: Color(0xFF9FE1CB), scale: 0.9),
      );
      // Android 13+ themed icon: one colour, the system tints it.
      await _render(
        '$dir/icon_monochrome.png',
        const LogoPainter(outer: Colors.white, inner: Colors.white, scale: 0.9),
      );
    });
  });
}
