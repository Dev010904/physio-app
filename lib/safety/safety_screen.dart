import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../program/program_controller.dart';
import '../session/session_log.dart';

/// India's single emergency number.
const emergencyNumber = '112';

/// Shown when a session stops for safety: high pain or a red-flag symptom.
/// It says what to do now and offers one-tap calls.
class SafetyStopScreen extends StatelessWidget {
  const SafetyStopScreen({super.key, this.flag, this.pain, this.link});

  final RedFlag? flag;
  final int? pain;
  final CareLink? link;

  Future<void> _call(BuildContext context, String number) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: number.replaceAll(' ', '')));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.cannotDial(number))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final urgent = flag == RedFlag.chestPain || flag == RedFlag.fall;
    final physioPhone = link?.phone;
    final l = context.l10n;
    final physioName = link?.clinicianName ?? link?.clinicName ?? l.yourPhysio;

    final advice = switch (flag) {
      RedFlag.chestPain => l.adviceChest,
      RedFlag.fall => l.adviceFall,
      RedFlag.numbness => l.adviceNumbness,
      RedFlag.severePain => l.adviceSeverePain,
      null => l.advicePain(pain ?? SafetyRules.stopPain),
    };

    return PopScope(
      child: Scaffold(
        backgroundColor: colors.errorContainer,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Icon(Icons.health_and_safety, size: 88, color: colors.onErrorContainer),
              const SizedBox(height: 16),
              Text(
                l.stopNow,
                style: text.headlineMedium?.copyWith(color: colors.onErrorContainer),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(advice, style: text.bodyLarge?.copyWith(color: colors.onErrorContainer), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              if (urgent || flag != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
                  onPressed: () => _call(context, emergencyNumber),
                  icon: const Icon(Icons.emergency, size: 28),
                  label: Text(l.callEmergency),
                ),
              if (physioPhone != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _call(context, physioPhone),
                  icon: const Icon(Icons.call, size: 26),
                  label: Text(l.callPhysio(physioName)),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: colors.onErrorContainer),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.imOk),
              ),
              const SizedBox(height: 20),
              Text(
                link == null ? l.notLinkedNobodyTold : l.physioWillSee(physioName),
                style: text.bodyMedium?.copyWith(color: colors.onErrorContainer),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
