import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:physio_app/camera/pose_rules.dart';
import 'package:physio_app/camera/rep_counter.dart';

const _rule = PoseRule(measure: 'test', placement: CameraPlacement.sideStanding, rest: 8, moved: 18, read: kneeBend);

/// Feeds [readings] 50 ms apart (20 frames a second) and returns the reps.
int _feed(RepCounter c, List<double> readings, {Duration start = Duration.zero, bool canStart = true}) {
  for (var i = 0; i < readings.length; i++) {
    c.add(readings[i], start + Duration(milliseconds: 50 * i), canStart: canStart);
  }
  return c.reps;
}

/// One slow rep from [rest] up by [range] and back, about 2 s.
List<double> _rep(double rest, double range) => [
  for (var i = 0; i <= 20; i++) rest + range * i / 20,
  for (var i = 20; i >= 0; i--) rest + range * i / 20,
];

PoseLandmark _at(PoseLandmarkType t, double x, double y, [double likelihood = 0.99]) =>
    PoseLandmark(type: t, x: x, y: y, z: 0, likelihood: likelihood);

void main() {
  group('RepCounter', () {
    test('counts each full rep once and keeps the furthest movement', () {
      final c = RepCounter(_rule);
      expect(_feed(c, [..._rep(0, 30), ..._rep(0, 45), ..._rep(0, 25)]), 3);
      expect(c.peak, closeTo(45, 2));
    });

    test('jitter around the "moved" line does not count extra reps', () {
      final c = RepCounter(_rule);
      final jitter = [for (var i = 0; i < 40; i++) i.isEven ? 16.0 : 22.0];
      expect(_feed(c, [0, 0, 0, ...jitter, 0, 0, 0, 0, 0]), 1);
    });

    test('noise below the line never counts', () {
      final c = RepCounter(_rule);
      expect(_feed(c, [for (var i = 0; i < 200; i++) i.isEven ? 0.0 : 12.0]), 0);
    });

    test('a twitch shorter than half a second is not a rep', () {
      final c = RepCounter(_rule);
      expect(_feed(c, [0, 0, 30, 30, 30, 0, 0, 0, 0]), 0);
    });

    test('measures from the patient\'s own resting position', () {
      // A glute bridge: lying with knees bent reads about 135 degrees.
      final c = RepCounter(_rule);
      expect(_feed(c, [..._rep(135, 35), ..._rep(135, 30)]), 2);
      expect(c.peak, closeTo(35, 2));
    });

    test('walking into place before a set does not shift the resting position', () {
      // Toes up while stepping read below flat; then the patient stands still.
      final c = RepCounter(_rule);
      _feed(c, [-15, -12, 5, -10, 3, for (var i = 0; i < 40; i++) 3.0], canStart: false);
      expect(_feed(c, [..._rep(3, 20), ..._rep(3, 20)], start: const Duration(seconds: 3)), 2);
    });

    test('no rep starts during a rest, but one under way can finish', () {
      final c = RepCounter(_rule);
      expect(_feed(c, _rep(0, 30), canStart: false), 0);
      // Up during the set, down after the rest began.
      _feed(c, [for (var i = 0; i <= 20; i++) 30.0 * i / 20]);
      expect(_feed(c, [for (var i = 20; i >= 0; i--) 30.0 * i / 20], start: const Duration(seconds: 2), canStart: false), 1);
    });
  });

  group('pose rules', () {
    // Image coordinates: x to the right, y downwards.
    Landmarks standing({double kneeBendDeg = 0}) {
      // Thigh straight down from the hip; the shin turns by the knee bend.
      final shin = kneeBendDeg * math.pi / 180;
      return {
        for (final side in [
          (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
          (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
        ]) ...{
          side.$1: _at(side.$1, 100, 100),
          side.$2: _at(side.$2, 100, 200),
          side.$3: _at(side.$3, 100 - 100 * math.sin(shin), 200 + 100 * math.cos(shin)),
        },
      };
    }

    test('knee bend reads 0 standing and the bend when squatting', () {
      expect(kneeBend(standing()), closeTo(0, 0.01));
      expect(kneeBend(standing(kneeBendDeg: 60)), closeTo(60, 0.01));
    });

    test('joints the camera cannot see clearly give no reading', () {
      final p = standing();
      for (final t in [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee]) {
        p[t] = _at(t, p[t]!.x, p[t]!.y, 0.2);
      }
      expect(kneeBend(p), isNull);
    });

    test('leg raise follows the leg that lifts', () {
      // Lying along x: shoulders at 0, hips at 200; the left leg lifts 40 degrees.
      final p = <PoseLandmarkType, PoseLandmark>{
        PoseLandmarkType.leftShoulder: _at(PoseLandmarkType.leftShoulder, 0, 300),
        PoseLandmarkType.rightShoulder: _at(PoseLandmarkType.rightShoulder, 0, 300),
        PoseLandmarkType.leftHip: _at(PoseLandmarkType.leftHip, 200, 300),
        PoseLandmarkType.rightHip: _at(PoseLandmarkType.rightHip, 200, 300),
        PoseLandmarkType.leftAnkle: _at(PoseLandmarkType.leftAnkle, 200 + 200 * math.cos(0.698), 300 - 200 * math.sin(0.698)),
        PoseLandmarkType.rightAnkle: _at(PoseLandmarkType.rightAnkle, 400, 300),
      };
      expect(legRaise(p), closeTo(40, 0.1));
    });

    test('hip line opens as the hips lift', () {
      Landmarks bridge(double hipY) => {
        PoseLandmarkType.leftShoulder: _at(PoseLandmarkType.leftShoulder, 0, 300),
        PoseLandmarkType.leftHip: _at(PoseLandmarkType.leftHip, 200, hipY),
        PoseLandmarkType.leftKnee: _at(PoseLandmarkType.leftKnee, 350, 200),
      };
      expect(hipLine(bridge(300))!, lessThan(150));
      expect(hipLine(bridge(240))!, greaterThan(165));
    });

    test('heel lift reads the tilt of the foot', () {
      Landmarks foot(double heelY) => {
        PoseLandmarkType.rightHeel: _at(PoseLandmarkType.rightHeel, 100, heelY),
        PoseLandmarkType.rightFootIndex: _at(PoseLandmarkType.rightFootIndex, 200, 500),
      };
      expect(heelLift(foot(500)), closeTo(0, 0.01));
      expect(heelLift(foot(500 - 100 * math.tan(0.349))), closeTo(20, 0.1));
    });

    test('knee opening is the angle between the thighs', () {
      Landmarks clam(double topKneeY) => {
        PoseLandmarkType.leftHip: _at(PoseLandmarkType.leftHip, 100, 320),
        PoseLandmarkType.leftKnee: _at(PoseLandmarkType.leftKnee, 250, 320),
        PoseLandmarkType.rightHip: _at(PoseLandmarkType.rightHip, 100, 280),
        PoseLandmarkType.rightKnee: _at(PoseLandmarkType.rightKnee, 250, topKneeY),
      };
      expect(kneeOpening(clam(280)), closeTo(0, 0.01));
      expect(kneeOpening(clam(280 - 150)), closeTo(45, 0.01));
    });

    test('only movements the camera can see are counted', () {
      expect(poseRules.keys, unorderedEquals(['wall_squat', 'straight_leg_raise', 'glute_bridge', 'heel_raise', 'clamshell']));
    });
  });
}

