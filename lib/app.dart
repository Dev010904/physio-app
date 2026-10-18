import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config/env.dart';

/// Working name until the brand is chosen (see the spec's open decisions).
const appName = 'Physio App';

class PhysioApp extends StatelessWidget {
  const PhysioApp({super.key});

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
      home: const StatusScreen(),
    );
  }
}

/// M0 home screen: shows which services this build is wired to.
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
      appBar: AppBar(title: const Text(appName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Foundation build (M0)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Your home exercise program will appear here.'),
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
