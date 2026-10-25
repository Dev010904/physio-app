import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open the phone app. Please dial $number.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final urgent = flag == RedFlag.chestPain || flag == RedFlag.fall;
    final physioPhone = link?.phone;
    final physioName = link?.clinicianName ?? link?.clinicName ?? 'your physio';

    final advice = switch (flag) {
      RedFlag.chestPain => 'Chest pain can be serious. Sit down and call emergency services now.',
      RedFlag.fall => 'Stay still and sit or lie down. If you hit your head, feel faint, or cannot get up, call emergency services.',
      RedFlag.numbness => 'Stop and rest. Tell your physio about the numbness or tingling before you exercise again.',
      RedFlag.severePain => 'Stop and rest the area. Do not continue this exercise until your physio has checked it.',
      null => 'Pain of ${pain ?? SafetyRules.stopPain} out of 10 is too much. Rest now, and check with your physio before your next session.',
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
                'Stop exercising now',
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
                  label: const Text('Call emergency 112'),
                ),
              if (physioPhone != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _call(context, physioPhone),
                  icon: const Icon(Icons.call, size: 26),
                  label: Text('Call $physioName'),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: colors.onErrorContainer),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("I'm OK, close"),
              ),
              const SizedBox(height: 20),
              Text(
                link == null
                    ? 'This app is not linked to a physio, so nobody has been told. Please contact your doctor or physio.'
                    : '$physioName will see this in your log as soon as your phone is online.',
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
