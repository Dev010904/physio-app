import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../exercises/exercise.dart';
import 'session_controller.dart';
import 'session_plan.dart';

/// Plays a session out loud: tones pace each rep (a lower, longer tone for
/// the release half), and the voice calls holds, rests and the last 3 seconds.
/// Uses the phone's own text-to-speech, so it works offline.
class CuePlayer implements SessionCues {
  CuePlayer(this.exercises);

  final List<Exercise> exercises;
  final voiceOn = ValueNotifier(true);

  final _tts = FlutterTts();
  final _players = <String, AudioPlayer>{};

  /// Holds shorter than this get no spoken countdown, so cues never overlap.
  static const _spokenCountdownMinSeconds = 5;

  /// Beeps take no audio focus, so they never pause the patient's music or
  /// cut off each other or the voice.
  static final _toneContext = AudioContext(
    android: const AudioContextAndroid(
      audioFocus: AndroidAudioFocus.none,
      usageType: AndroidUsageType.assistanceSonification,
      contentType: AndroidContentType.sonification,
    ),
  );

  Future<void> init() async {
    for (final name in const ['move', 'release', 'tick', 'done']) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setAudioContext(_toneContext);
      _players[name] = player;
    }
    try {
      final hasIndianEnglish = await _tts.isLanguageAvailable('en-IN') == true;
      await _tts.setLanguage(hasIndianEnglish ? 'en-IN' : 'en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(false);
      // Spoken like navigation prompts: other audio dips briefly, then returns.
      await _tts.setAudioAttributesForNavigation();
    } catch (e) {
      debugPrint('Text-to-speech unavailable: $e');
    }
  }

  @override
  void phaseStarted(Phase phase) {
    final exercise = exercises[phase.exerciseIndex];
    switch (phase.kind) {
      case PhaseKind.prepare:
        final firstOfExercise = phase.set == 1 && phase.side != Side.right;
        final what = phase.side == null ? 'Get ready' : '${_sideName(phase.side!)} side';
        _say(firstOfExercise ? '${exercise.title}. $what' : what);
      case PhaseKind.move:
        _tone('move');
      case PhaseKind.hold:
        if (phase.seconds >= 3) _say('Hold');
      case PhaseKind.release:
        _tone('release');
      case PhaseKind.timed:
        _tone('move');
        _say('Start');
      case PhaseKind.rest:
        _say('Rest');
      case PhaseKind.transition:
        _say('Next, ${exercise.title}');
    }
  }

  @override
  void countdown(int secondsLeft, Phase phase) {
    final speak = voiceOn.value &&
        phase.kind != PhaseKind.prepare &&
        phase.seconds >= _spokenCountdownMinSeconds;
    speak ? _say('$secondsLeft') : _tone('tick');
  }

  @override
  void finished() {
    _tone('done');
    _say('Session complete. Well done.');
  }

  void _say(String text) {
    if (!voiceOn.value) return;
    _tts.speak(text, focus: true).catchError((Object e) => debugPrint('speak failed: $e'));
  }

  void _tone(String name) {
    _players[name]
        ?.play(AssetSource('sounds/$name.wav'), mode: PlayerMode.lowLatency)
        .catchError((Object e) => debugPrint('tone $name failed: $e'));
  }

  static String _sideName(Side side) => side == Side.left ? 'Left' : 'Right';

  Future<void> dispose() async {
    voiceOn.dispose();
    await _tts.stop();
    for (final p in _players.values) {
      await p.dispose();
    }
  }
}
