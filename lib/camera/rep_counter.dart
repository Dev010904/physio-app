import 'dart:math' as math;

import 'pose_rules.dart';

/// Counts reps from one reading per camera frame (see [PoseRule.read]).
/// Movement is measured from the patient's resting position: where they
/// settle while getting ready and between sets, and never above the lowest
/// reading during a set. A rep counts when the movement passes [PoseRule.moved] and
/// then comes back under [PoseRule.rest]. The gap between the two lines is
/// hysteresis, so jitter near either line never counts twice.
class RepCounter {
  RepCounter(this.rule);

  final PoseRule rule;

  /// Light smoothing; at 20+ frames a second this settles in about 0.1 s.
  static const _smoothing = 0.5;

  /// How quickly the resting position follows the patient between sets.
  static const _settling = 0.1;

  /// A movement shorter than this is a twitch or a detection glitch.
  static const minRep = Duration(milliseconds: 500);

  int _reps = 0;
  bool _out = false;
  Duration _outSince = Duration.zero;
  double? _value;
  double? _rest;
  double _repPeak = 0;
  double? _peak;

  int get reps => _reps;

  /// The furthest movement over the counted reps, in degrees from rest.
  double? get peak => _peak;

  /// The movement now, in degrees from rest; null while the patient is unseen.
  double? get movement => _value == null ? null : _value! - _rest!;

  /// True while a rep is under way.
  bool get isMoving => _out;

  /// Feeds one frame's reading, taken at [at]. With [canStart] false (during
  /// a rest) no new rep begins, but one under way can still finish. Returns
  /// true when this frame completed a rep.
  bool add(double reading, Duration at, {bool canStart = true}) {
    final v = _value = _value == null ? reading : _value! + (reading - _value!) * _smoothing;
    final rest = _rest = _rest == null
        ? v
        : !_out && !canStart
        ? _rest! + (v - _rest!) * _settling
        : math.min(_rest!, v);
    final moved = v - rest;
    if (!_out) {
      if (canStart && moved >= rule.moved) {
        _out = true;
        _outSince = at;
        _repPeak = moved;
      }
      return false;
    }
    _repPeak = math.max(_repPeak, moved);
    if (moved > rule.rest) return false;
    _out = false;
    if (at - _outSince < minRep) return false;
    _reps++;
    _peak = math.max(_peak ?? _repPeak, _repPeak);
    return true;
  }

  /// The patient left the picture: forget the smoothing so an old reading
  /// does not drag the next one. A rep under way can still finish.
  void lost() => _value = null;
}
