// Generates the session cue tones in assets/sounds/.
// Run from the project root: dart run tool/gen_tones.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;

/// A sine note with short fades so it never clicks.
List<double> note(double hz, int ms, {double volume = 0.6}) {
  final n = sampleRate * ms ~/ 1000;
  final fade = sampleRate * 8 ~/ 1000;
  return List.generate(n, (i) {
    final edge = min(1.0, min(i, n - 1 - i) / fade);
    return volume * edge * sin(2 * pi * hz * i / sampleRate);
  });
}

Uint8List wav(List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // PCM chunk size
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  final tones = {
    // First half of a rep: short and high.
    'move': note(880, 140),
    // Lowering half: lower and longer, so it is told apart without looking.
    'release': note(523.25, 240),
    'tick': note(1320, 60, volume: 0.5),
    'done': [...note(659.25, 150), ...note(987.77, 280)],
  };
  final dir = Directory('assets/sounds')..createSync(recursive: true);
  tones.forEach((name, samples) {
    File('${dir.path}/$name.wav').writeAsBytesSync(wav(samples));
    stdout.writeln('wrote ${dir.path}/$name.wav (${samples.length} samples)');
  });
}
