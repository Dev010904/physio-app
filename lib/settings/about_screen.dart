import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../branding/logo.dart';
import '../config/env.dart';
import '../onboarding/welcome.dart';
import 'appearance.dart';

/// Settings and build information.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.appearance});

  final AppearanceController appearance;

  Future<void> _sendTestEvent(BuildContext context) async {
    final id = await Sentry.captureException(StateError('Test event: Sentry wiring check'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent to Sentry: $id')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Center(child: Wordmark(size: 40)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Your physio companion',
              style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 28),
          Text('Appearance', style: text.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: appearance,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Phone'), icon: Icon(Icons.smartphone)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
              ],
              selected: {mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => appearance.set(s.first),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.waving_hand_outlined),
            title: const Text('Welcome tour'),
            subtitle: const Text('How tutorials and the glow colours work'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => WelcomeScreen(onDone: () => Navigator.of(context).pop())),
            ),
          ),
          const SizedBox(height: 20),
          Text('This build', style: text.titleMedium),
          const SizedBox(height: 4),
          _StatusTile(label: 'Works offline', ok: true),
          _StatusTile(label: 'Crash reporting', ok: Env.hasSentry),
          _StatusTile(label: 'Backend sync', ok: Env.hasSupabase),
          if (Env.hasSentry && Env.environment == 'dev') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _sendTestEvent(context),
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Send test event to Sentry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
          color: ok ? colors.primary : colors.outline),
      title: Text(label),
      trailing: Text(ok ? 'On' : 'Not set up', style: TextStyle(color: colors.onSurfaceVariant)),
    );
  }
}
