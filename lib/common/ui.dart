import 'package:flutter/material.dart';

/// "about 4 min" for planning; rounds up so the estimate is never short.
String minutesLabel(Duration d) => 'about ${(d.inSeconds / 60).ceil()} min';

/// "4:05" for clocks.
String clockLabel(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

IconData bodyRegionIcon(String region) => switch (region) {
  'knee' => Icons.directions_walk,
  'hip' => Icons.accessibility_new,
  'ankle' => Icons.directions_run,
  'back' => Icons.airline_seat_flat,
  'neck' => Icons.face,
  'shoulder' => Icons.fitness_center,
  _ => Icons.self_improvement,
};

String capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Shown until a physiotherapist has reviewed the starter instructions.
class DraftContentNotice extends StatelessWidget {
  const DraftContentNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: ListTile(
        leading: Icon(Icons.edit_note, color: colors.onSecondaryContainer),
        title: Text(
          'Draft instructions, not yet reviewed by a physiotherapist.',
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
      ),
    );
  }
}

class SafetyNotice extends StatelessWidget {
  const SafetyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: ListTile(
        leading: Icon(Icons.health_and_safety_outlined, color: colors.onErrorContainer),
        title: Text(
          'Stop and contact your physiotherapist if you feel sharp pain, numbness, '
          'or pain above 7 out of 10.',
          style: TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}
