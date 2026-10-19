import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config/env.dart';
import 'exercises/exercise.dart';
import 'home/today_screen.dart';

/// Chosen 2026-10-19 (Play Store and .com checked; trademark search still to do).
const appName = 'PhysioSathi';

class PhysioApp extends StatelessWidget {
  const PhysioApp({super.key, required this.library});

  final ExerciseLibrary library;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: TodayScreen(library: library),
    );
  }
}

/// Shows which services this build is wired to (reached from Today's info button).
class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  Future<void> _sendTestEvent(BuildContext context) async {
    final id = await Sentry.captureException(StateError('M0 test event: Sentry wiring check'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent to Sentry: $id')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About this build')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('$appName · development build', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          _StatusTile(label: 'Crash reporting', ok: Env.hasSentry),
          _StatusTile(label: 'Backend sync', ok: Env.hasSupabase),
          const _StatusTile(label: 'Works offline', ok: true),
          const SizedBox(height: 24),
          if (Env.hasSentry)
            OutlinedButton.icon(
              onPressed: () => _sendTestEvent(context),
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Send test event to Sentry'),
            ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok ? Icons.check_circle : Icons.radio_button_unchecked,
        color: ok ? Colors.teal : Theme.of(context).disabledColor,
      ),
      title: Text(label),
      trailing: Text(ok ? 'On' : 'Not configured'),
    );
  }
}
