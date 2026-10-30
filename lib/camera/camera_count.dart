import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'pose_rules.dart';
import 'rep_counter.dart';

/// One camera frame's pose, in the upright picture's coordinates.
class PoseFrame {
  const PoseFrame(this.landmarks, this.size, {required this.mirrored});

  /// Null when no one is in the picture.
  final Landmarks? landmarks;
  final Size size;

  /// The front camera's preview is a mirror image, so the overlay flips too.
  final bool mirrored;
}

/// What the camera counts during one exercise. Listeners hear only when the
/// count or visibility changes; the overlay repaints from [pose] instead.
class CameraCount extends ChangeNotifier {
  CameraCount(this.exerciseIndex, this.rule, {required this.wholeExercise}) : counter = RepCounter(rule);

  final int exerciseIndex;
  final PoseRule rule;
  final RepCounter counter;

  /// True when the camera watched from before the first rep, so its count
  /// can stand in for the timer's.
  final bool wholeExercise;

  /// How long the patient may drop out of the picture before we ask them
  /// to move, so a moment of doubt in the detector does not flash a warning.
  static const _graceUnseen = Duration(seconds: 1);

  final pose = ValueNotifier<PoseFrame?>(null);
  Duration? _lastSeen;
  bool _seen = true;

  /// False once the patient has been out of view for a moment.
  bool get seen => _seen;

  void addFrame(PoseFrame frame, Duration at, {required bool canStart}) {
    pose.value = frame;
    final landmarks = frame.landmarks;
    final reading = landmarks == null ? null : rule.read(landmarks);
    final reps = counter.reps;
    _lastSeen ??= at;
    if (reading == null) {
      counter.lost();
    } else {
      _lastSeen = at;
      counter.add(reading, at, canStart: canStart);
    }
    final seen = at - _lastSeen! <= _graceUnseen;
    if (seen != _seen || counter.reps != reps) {
      _seen = seen;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pose.dispose();
    super.dispose();
  }
}
