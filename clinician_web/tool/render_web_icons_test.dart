// Renders the PhysioSathi logo to the dashboard's favicon and web app icons.
// Run from clinician_web/: flutter test tool/render_web_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/branding/logo.dart';

const _teal = Color(0xFF0F6E56);

Future<void> _render(String path, int size, {bool maskable = false}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final box = Size.square(size.toDouble());
  if (maskable) {
    // Maskable icons are cropped to a circle or squircle: fill edge to edge and
    // keep the mark inside the 80% safe zone.
    canvas.drawRect(Offset.zero & box, Paint()..color = _teal);
    const LogoPainter(outer: Colors.white, inner: Color(0xFF9FE1CB), scale: 0.78).paint(canvas, box);
  } else {
    const LogoPainter.tile().paint(canvas, box);
  }
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('render web icons', (tester) async {
    await tester.runAsync(() async {
      await _render('web/favicon.png', 64);
      await _render('web/icons/Icon-192.png', 192);
      await _render('web/icons/Icon-512.png', 512);
      await _render('web/icons/Icon-maskable-192.png', 192, maskable: true);
      await _render('web/icons/Icon-maskable-512.png', 512, maskable: true);
    });
  });
}
