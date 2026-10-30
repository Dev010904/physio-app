import 'dart:math' as math;

import 'package:flutter/material.dart';

/// What an exercise does to a muscle. Each effect has the glow colour used in
/// the tutorial footage.
enum Effect {
  works(Color(0xFFF26B1D)),
  stretches(Color(0xFF9A5BF0)),
  loosens(Color(0xFF22B8A6));

  const Effect(this.color);

  final Color color;
}

/// Realistic footage of one rep, start pose to end pose, with the target
/// muscles glowing as they work. The frames sit in one sheet, rows of
/// [columns], built by tool/build_tutorials.sh from the clips in art/tutorials.
class Tutorial {
  const Tutorial(this.id, {required this.frames, required this.muscles, this.musclesHi = const {}, this.sway = false});

  static const columns = 5;

  final String id;

  /// Frames in the sheet; 2 means a start and end photo, cross-faded.
  final int frames;

  /// Muscle names by effect, in the order shown.
  final Map<Effect, List<String>> muscles;

  /// The same muscles in Hindi (draft, for physio review).
  final Map<Effect, List<String>> musclesHi;

  /// Muscle names in [lang], falling back to English.
  Map<Effect, List<String>> musclesIn(String lang) => lang == 'hi' && musclesHi.isNotEmpty ? musclesHi : muscles;

  /// Keeps swinging while held (pendulum) instead of moving once per rep.
  final bool sway;

  String get sheet => 'assets/tutorials/$id.webp';
  String get poster => 'assets/tutorials/${id}_poster.webp';
}

/// Frame counts must match tool/build_tutorials.sh.
const tutorials = <String, Tutorial>{
  'wall_squat': Tutorial(
    'wall_squat',
    frames: 25,
    muscles: {
      Effect.works: ['Quadriceps (front of thigh)', 'Glutes'],
    },
    musclesHi: {
      Effect.works: ['क्वाड्रिसेप्स (जांघ का अगला हिस्सा)', 'कूल्हे की मांसपेशियाँ (ग्लूट्स)'],
    },
  ),
  'straight_leg_raise': Tutorial(
    'straight_leg_raise',
    frames: 25,
    muscles: {
      Effect.works: ['Quadriceps (front of thigh)', 'Hip flexors'],
    },
    musclesHi: {
      Effect.works: ['क्वाड्रिसेप्स (जांघ का अगला हिस्सा)', 'हिप फ़्लेक्सर (कूल्हे के आगे)'],
    },
  ),
  'heel_raise': Tutorial(
    'heel_raise',
    frames: 25,
    muscles: {
      Effect.works: ['Calf (gastrocnemius and soleus)'],
    },
    musclesHi: {
      Effect.works: ['पिंडली की मांसपेशियाँ'],
    },
  ),
  'glute_bridge': Tutorial(
    'glute_bridge',
    frames: 25,
    muscles: {
      Effect.works: ['Glutes', 'Hamstrings (back of thigh)'],
    },
    musclesHi: {
      Effect.works: ['कूल्हे की मांसपेशियाँ (ग्लूट्स)', 'हैमस्ट्रिंग (जांघ का पिछला हिस्सा)'],
    },
  ),
  'clamshell': Tutorial(
    'clamshell',
    frames: 25,
    muscles: {
      Effect.works: ['Gluteus medius (side of hip)'],
    },
    musclesHi: {
      Effect.works: ['ग्लूटियस मीडियस (कूल्हे की बगल)'],
    },
  ),
  'quad_set': Tutorial(
    'quad_set',
    frames: 25,
    muscles: {
      Effect.works: ['Quadriceps (front of thigh)'],
    },
    musclesHi: {
      Effect.works: ['क्वाड्रिसेप्स (जांघ का अगला हिस्सा)'],
    },
  ),
  'cat_cow': Tutorial(
    'cat_cow',
    frames: 17,
    muscles: {
      Effect.works: ['Abdominals'],
      Effect.stretches: ['Back muscles'],
    },
    musclesHi: {
      Effect.works: ['पेट की मांसपेशियाँ'],
      Effect.stretches: ['पीठ की मांसपेशियाँ'],
    },
  ),
  'chin_tuck': Tutorial(
    'chin_tuck',
    frames: 23,
    muscles: {
      Effect.works: ['Deep neck flexors (front of neck)'],
      Effect.stretches: ['Back of neck'],
    },
    musclesHi: {
      Effect.works: ['गर्दन के आगे की गहरी मांसपेशियाँ'],
      Effect.stretches: ['गर्दन का पिछला हिस्सा'],
    },
  ),
  'pendulum': Tutorial(
    'pendulum',
    frames: 12,
    sway: true,
    muscles: {
      Effect.loosens: ['Shoulder joint (kept relaxed)'],
    },
    musclesHi: {
      Effect.loosens: ['कंधे का जोड़ (ढीला रखें)'],
    },
  ),
  'calf_stretch': Tutorial(
    'calf_stretch',
    frames: 25,
    muscles: {
      Effect.stretches: ['Calf of the back leg'],
    },
    musclesHi: {
      Effect.stretches: ['पीछे वाले पैर की पिंडली'],
    },
  ),
};

/// Progress for a looping demonstration: move, hold briefly, return, pause.
double demoProgress(double phase, Tutorial tutorial) {
  if (tutorial.sway) return 0.5 - 0.5 * math.cos(phase * 2 * math.pi);
  // 0-0.35 move, 0.35-0.6 hold, 0.6-0.95 return, 0.95-1 rest.
  if (phase < 0.35) return Curves.easeInOut.transform(phase / 0.35);
  if (phase < 0.6) return 1;
  if (phase < 0.95) return 1 - Curves.easeInOut.transform((phase - 0.6) / 0.35);
  return 0;
}
