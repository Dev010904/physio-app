import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

typedef Landmarks = Map<PoseLandmarkType, PoseLandmark>;

/// Where the phone stands for an exercise, so the moving joints face it.
enum CameraPlacement {
  /// Standing, with the phone to one side.
  sideStanding,

  /// Lying on the back, with the phone on the floor to one side.
  sideLying,

  /// Lying on one side, with the phone on the floor in front.
  frontLying,
}

/// How the camera measures one exercise. [read] turns a pose into degrees
/// that grow as the patient moves, or null when the joints it needs are not
/// clearly seen. [rest] and [moved] are degrees from the patient's own
/// resting position (the lowest reading), so they suit any body and any
/// small tilt of the phone.
class PoseRule {
  const PoseRule({required this.measure, required this.placement, required this.rest, required this.moved, required this.read});

  /// What the degrees mean, for the physio's records.
  final String measure;
  final CameraPlacement placement;
  final double rest;
  final double moved;
  final double? Function(Landmarks pose) read;
}

/// The exercises the camera can count. The rest move too little (quad set,
/// chin tuck), have no spine points to read (cat-cow) or are timed holds.
const poseRules = <String, PoseRule>{
  'wall_squat': PoseRule(measure: 'knee_bend', placement: CameraPlacement.sideStanding, rest: 10, moved: 20, read: kneeBend),
  'straight_leg_raise': PoseRule(measure: 'leg_raise', placement: CameraPlacement.sideLying, rest: 8, moved: 18, read: legRaise),
  'glute_bridge': PoseRule(measure: 'hip_lift', placement: CameraPlacement.sideLying, rest: 7, moved: 15, read: hipLine),
  'heel_raise': PoseRule(measure: 'heel_lift', placement: CameraPlacement.sideStanding, rest: 5, moved: 10, read: heelLift),
  'clamshell': PoseRule(measure: 'knee_opening', placement: CameraPlacement.frontLying, rest: 8, moved: 18, read: kneeOpening),
};

/// Landmarks less likely than this are treated as unseen.
const minLikelihood = 0.5;

typedef _Body = ({
  PoseLandmarkType shoulder,
  PoseLandmarkType hip,
  PoseLandmarkType knee,
  PoseLandmarkType ankle,
  PoseLandmarkType heel,
  PoseLandmarkType toe,
});

const _Body _left = (
  shoulder: PoseLandmarkType.leftShoulder,
  hip: PoseLandmarkType.leftHip,
  knee: PoseLandmarkType.leftKnee,
  ankle: PoseLandmarkType.leftAnkle,
  heel: PoseLandmarkType.leftHeel,
  toe: PoseLandmarkType.leftFootIndex,
);

const _Body _right = (
  shoulder: PoseLandmarkType.rightShoulder,
  hip: PoseLandmarkType.rightHip,
  knee: PoseLandmarkType.rightKnee,
  ankle: PoseLandmarkType.rightAnkle,
  heel: PoseLandmarkType.rightHeel,
  toe: PoseLandmarkType.rightFootIndex,
);

/// Knee bend from straight: 180 minus the hip-knee-ankle angle.
double? kneeBend(Landmarks p) => _oneSide(p, (s) => [s.hip, s.knee, s.ankle], (j) => 180 - angleAt(j[0], j[1], j[2]));

/// How far a straight leg is lifted from the line of the body. Only one leg
/// lifts, so the side that reads higher is the one moving.
double? legRaise(Landmarks p) =>
    _oneSide(p, (s) => [s.shoulder, s.hip, s.ankle], (j) => 180 - angleAt(j[0], j[1], j[2]), moving: true);

/// The shoulder-hip-knee angle; it opens towards a straight line as the hips lift.
double? hipLine(Landmarks p) => _oneSide(p, (s) => [s.shoulder, s.hip, s.knee], (j) => angleAt(j[0], j[1], j[2]));

/// Tilt of the foot, heel above toes, in degrees.
double? heelLift(Landmarks p) => _oneSide(p, (s) => [s.heel, s.toe], (j) {
  final (heel, toe) = (j[0], j[1]);
  // Image y grows downwards, so a raised heel has the smaller y.
  return math.atan2(toe.y - heel.y, (toe.x - heel.x).abs()) * 180 / math.pi;
});

/// The angle between the two thighs; the knees part as the top one lifts.
double? kneeOpening(Landmarks p) {
  final j = _seenAll(p, [_left.hip, _left.knee, _right.hip, _right.knee]);
  if (j == null) return null;
  return _between(j[1].x - j[0].x, j[1].y - j[0].y, j[3].x - j[2].x, j[3].y - j[2].y);
}

/// The angle at [b] between [a] and [c], 0 to 180 degrees.
double angleAt(PoseLandmark a, PoseLandmark b, PoseLandmark c) => _between(a.x - b.x, a.y - b.y, c.x - b.x, c.y - b.y);

double _between(double ax, double ay, double bx, double by) =>
    math.atan2(ax * by - ay * bx, ax * bx + ay * by).abs() * 180 / math.pi;

List<PoseLandmark>? _seenAll(Landmarks p, List<PoseLandmarkType> types) {
  final seen = <PoseLandmark>[];
  for (final t in types) {
    final l = p[t];
    if (l == null || l.likelihood < minLikelihood) return null;
    seen.add(l);
  }
  return seen;
}

/// Reads [measure] on the clearer side of the body, or with [moving], on the
/// side that reads higher. Null when neither side is clearly seen.
double? _oneSide(
  Landmarks p,
  List<PoseLandmarkType> Function(_Body side) joints,
  double Function(List<PoseLandmark> joints) measure, {
  bool moving = false,
}) {
  double? value;
  var clarity = -1.0;
  for (final side in [_left, _right]) {
    final j = _seenAll(p, joints(side));
    if (j == null) continue;
    final v = measure(j);
    final c = j.fold(0.0, (sum, l) => sum + l.likelihood);
    if (value == null || (moving ? v > value : c > clarity)) {
      value = v;
      clarity = c;
    }
  }
  return value;
}
