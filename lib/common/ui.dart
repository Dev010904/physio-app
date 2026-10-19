import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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

/// Body-region icon on a soft round badge.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.region, this.size = 44});

  final String region;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
      child: Icon(bodyRegionIcon(region), size: size * 0.52, color: Theme.of(context).colorScheme.onSurface),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.background, required this.foreground});

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(Brand.of(context).radius)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: foreground, fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }
}

/// Shown until a physiotherapist has reviewed the starter instructions.
class DraftContentNotice extends StatelessWidget {
  const DraftContentNotice({super.key});

  @override
  Widget build(BuildContext context) => _Notice(
    icon: Icons.edit_note,
    text: 'Draft instructions, not yet reviewed by a physiotherapist.',
    background: Brand.of(context).soft,
    foreground: Theme.of(context).colorScheme.onSurface,
  );
}

class SafetyNotice extends StatelessWidget {
  const SafetyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Notice(
      icon: Icons.health_and_safety_outlined,
      text: 'Stop and contact your physiotherapist if you feel sharp pain, numbness, '
          'or pain above 7 out of 10.',
      background: colors.errorContainer,
      foreground: colors.onErrorContainer,
    );
  }
}
