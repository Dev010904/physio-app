import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../branding/logo.dart';
import '../config/env.dart';
import '../l10n/l10n.dart';
import '../link/link_screen.dart';
import '../onboarding/welcome.dart';
import '../program/program_controller.dart';
import '../reminders/reminders.dart';
import 'appearance.dart';
import 'language.dart';

/// Settings and build information.
class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    required this.appearance,
    required this.programs,
    required this.reminders,
    required this.language,
  });

  final AppearanceController appearance;
  final ProgramController programs;
  final ReminderController reminders;
  final LanguageController language;

  Future<void> _sendTestEvent(BuildContext context) async {
    final id = await Sentry.captureException(StateError('Test event: Sentry wiring check'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent to Sentry: $id')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Center(child: Wordmark(size: 40)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l.appTagline,
              style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 28),
          Text(l.myPhysio, style: text.titleMedium),
          const SizedBox(height: 4),
          ListenableBuilder(listenable: programs, builder: (context, _) => _PhysioSection(programs: programs)),
          const SizedBox(height: 20),
          Text(l.reminder, style: text.titleMedium),
          const SizedBox(height: 4),
          _ReminderSection(reminders: reminders),
          const SizedBox(height: 20),
          Text(l.language, style: text.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: language,
            builder: (context, lang, _) => SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'phone', label: Text(l.languagePhone), icon: const Icon(Icons.smartphone)),
                const ButtonSegment(value: 'en', label: Text('English')),
                const ButtonSegment(value: 'hi', label: Text('हिन्दी')),
              ],
              selected: {lang ?? 'phone'},
              showSelectedIcon: false,
              onSelectionChanged: (s) => language.set(s.first == 'phone' ? null : s.first),
            ),
          ),
          const SizedBox(height: 20),
          Text(l.appearance, style: text.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: appearance,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l.themePhone), icon: const Icon(Icons.smartphone)),
                ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight), icon: const Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark), icon: const Icon(Icons.dark_mode_outlined)),
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
            title: Text(l.welcomeTour),
            subtitle: Text(l.welcomeTourBody),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => WelcomeScreen(onDone: () => Navigator.of(context).pop())),
            ),
          ),
          const SizedBox(height: 20),
          Text(l.yourData, style: text.titleMedium),
          const SizedBox(height: 4),
          ListenableBuilder(listenable: programs, builder: (context, _) => _DataSection(programs: programs)),
          const SizedBox(height: 20),
          Text(l.thisBuild, style: text.titleMedium),
          const SizedBox(height: 4),
          _StatusTile(label: l.worksOffline, ok: true),
          _StatusTile(label: l.crashReporting, ok: Env.hasSentry),
          _StatusTile(label: l.backendSync, ok: Env.hasSupabase),
          if (Env.hasSentry && Env.environment == 'dev') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _sendTestEvent(context),
              icon: const Icon(Icons.bug_report_outlined),
              label: Text(l.sendTestEvent),
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
      trailing: Text(ok ? context.l10n.statusOn : context.l10n.statusNotSetUp, style: TextStyle(color: colors.onSurfaceVariant)),
    );
  }
}

class _PhysioSection extends StatelessWidget {
  const _PhysioSection({required this.programs});

  final ProgramController programs;

  @override
  Widget build(BuildContext context) {
    final link = programs.link;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    void openLink() => Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => LinkScreen(programs: programs)));
    if (link == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.link_off_rounded),
        title: Text(context.l10n.notLinked),
        subtitle: Text(programs.canLink ? context.l10n.notLinkedBody : context.l10n.linkUnavailable),
        trailing: programs.canLink ? const Icon(Icons.chevron_right) : null,
        onTap: programs.canLink ? openLink : null,
      );
    }
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_hospital_outlined),
          title: Text(link.clinicianName ?? link.clinicName ?? context.l10n.myPhysio),
          subtitle: Text(
            [
              if (link.clinicName != null && link.clinicianName != null) link.clinicName!,
              if (link.phone != null) link.phone!,
              context.l10n.linkedAs(link.displayName),
            ].join(' · '),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.qr_code_2_rounded, color: muted),
          title: Text(context.l10n.useNewCode),
          subtitle: Text(context.l10n.useNewCodeBody),
          trailing: const Icon(Icons.chevron_right),
          onTap: openLink,
        ),
      ],
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection({required this.programs});

  final ProgramController programs;

  Future<void> _delete(BuildContext context) async {
    final l = context.l10n;
    final linked = programs.isLinked;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(linked ? l.deleteConfirmLinkedBody : l.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.deleteAction),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await programs.deleteAllData();
      messenger.showSnackBar(SnackBar(content: Text(l.dataDeleted)));
    } catch (e) {
      debugPrint('delete failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.deleteNeedsInternet)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.delete_forever_outlined, color: error),
      title: Text(l.deleteMyData, style: TextStyle(color: error)),
      subtitle: Text(programs.isLinked ? l.deleteMyDataLinkedBody : l.deleteMyDataBody),
      onTap: () => _delete(context),
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({required this.reminders});

  final ReminderController reminders;

  Future<void> _turnOn(BuildContext context, TimeOfDay time) async {
    final l = context.l10n;
    final ok = await reminders.enable(time, title: l.reminderTitle, body: l.reminderBody);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.notificationsOff)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: reminders,
      builder: (context, settings, _) => Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(context.l10n.remindDaily),
            value: settings.enabled,
            onChanged: (on) => on ? _turnOn(context, settings.time) : reminders.disable(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(context.l10n.reminderTime),
            trailing: Text(settings.time.format(context), style: Theme.of(context).textTheme.titleMedium),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: settings.time);
              if (picked != null && context.mounted) await _turnOn(context, picked);
            },
          ),
        ],
      ),
    );
  }
}
