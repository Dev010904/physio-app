import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/text.dart';
import 'add_patient_screen.dart';
import 'patient_screen.dart';
import 'scope.dart';
import 'shell.dart';
import 'widgets.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _search = TextEditingController();
  bool _attentionOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Loader<List<PatientSummary>>(
      load: scope.api.patients,
      refreshOn: scope.changes,
      loadingLabel: 'Loading your patients…',
      builder: (context, patients, reload) {
        final query = _search.text.trim().toLowerCase();
        final shown = [
          for (final p in patients)
            if ((query.isEmpty || p.patient.displayName.toLowerCase().contains(query)) && (!_attentionOnly || p.needsAttention)) p,
        ];
        final attention = patients.where((p) => p.needsAttention).length;
        return RefreshIndicator(
          onRefresh: reload,
          child: PageBody(
            children: [
              PageHeader(
                title: 'Patients',
                subtitle: Text(
                  patients.isEmpty
                      ? 'Add a patient to give them a code for the app.'
                      : '${patients.length} ${patients.length == 1 ? 'patient' : 'patients'}'
                            '${attention > 0 ? ' · $attention ${attention == 1 ? 'needs' : 'need'} attention' : ''}',
                ),
                actions: [
                  FilledButton.icon(
                    style: compactButton,
                    onPressed: () => Navigator.of(context).push(pageRoute(const AddPatientScreen(), 'add')),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add patient'),
                  ),
                ],
              ),
              if (patients.isNotEmpty) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Search by name',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () => setState(_search.clear),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                    FilterChip(
                      label: Text('Needs attention ($attention)'),
                      avatar: const Icon(Icons.priority_high, size: 18),
                      selected: _attentionOnly,
                      onSelected: (v) => setState(() => _attentionOnly = v),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              if (patients.isEmpty)
                Panel(
                  child: EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No patients yet',
                    message: 'Add your first patient. You will get a code for them to enter in the PhysioSathi app.',
                    action: FilledButton.icon(
                      style: compactButton,
                      onPressed: () => Navigator.of(context).push(pageRoute(const AddPatientScreen(), 'add')),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add your first patient'),
                    ),
                  ),
                )
              else if (shown.isEmpty)
                Panel(
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No one matches',
                    message: _attentionOnly && query.isEmpty ? 'Nobody needs attention right now.' : 'Try a different name.',
                  ),
                )
              else
                _PatientList(patients: shown),
            ],
          ),
        );
      },
    );
  }
}

class _PatientList extends StatelessWidget {
  const _PatientList({required this.patients});

  final List<PatientSummary> patients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final headerStyle = theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 14);
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          if (wide)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  const SizedBox(width: 58),
                  Expanded(flex: 4, child: Text('Name', style: headerStyle)),
                  Expanded(flex: 3, child: Text('Phone app', style: headerStyle)),
                  Expanded(flex: 3, child: Text('Last session', style: headerStyle)),
                  Expanded(flex: 2, child: Text('Last 7 days', style: headerStyle)),
                  Expanded(flex: 3, child: Text('Needs attention', style: headerStyle)),
                  const SizedBox(width: 32),
                ],
              ),
            ),
          for (var i = 0; i < patients.length; i++) ...[
            if (i > 0 || wide) const Divider(height: 1),
            _PatientRowTile(summary: patients[i], wide: wide),
          ],
        ],
      ),
    );
  }
}

class _PatientRowTile extends StatelessWidget {
  const _PatientRowTile({required this.summary, required this.wide});

  final PatientSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final p = summary.patient;
    final now = DateTime.now();
    final last = summary.lastSession;
    final rate = summary.adherence.rate(7);

    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.displayName, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
        Text(
          summary.hasProgram ? p.languageLabel : '${p.languageLabel} · no program yet',
          style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
    final linked = p.linked
        ? const Pill('Linked', icon: Icons.phone_android, tone: Tone.good)
        : const Pill('Not linked yet', icon: Icons.link_off, tone: Tone.neutral);
    final lastText = Text(
      last == null ? 'No sessions yet' : relativeDay(last, now),
      style: theme.textTheme.bodyLarge?.copyWith(color: last == null ? c.onSurfaceVariant : null),
    );
    final rateText = Text(rate == null ? '–' : '${(rate * 100).round()}%', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600));
    final attention = [
      if (summary.openFlags > 0)
        Pill('${summary.openFlags} open ${summary.openFlags == 1 ? 'flag' : 'flags'}', icon: Icons.flag, tone: Tone.bad),
      if (summary.adherence.showMissedWarning) Pill('Missed ${summary.adherence.missedInARow} days', icon: Icons.event_busy, tone: Tone.warn),
    ];

    void open() => Navigator.of(context).push(pageRoute(PatientScreen(patientId: p.id, name: p.displayName), 'patient'));

    return InkWell(
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: wide
            ? Row(
                children: [
                  InitialsAvatar(initials(p.displayName)),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: name),
                  Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: linked)),
                  Expanded(flex: 3, child: lastText),
                  Expanded(flex: 2, child: rateText),
                  Expanded(
                    flex: 3,
                    child: attention.isEmpty
                        ? Text('–', style: TextStyle(color: c.onSurfaceVariant))
                        : Wrap(spacing: 6, runSpacing: 6, children: attention),
                  ),
                  Icon(Icons.chevron_right, color: c.onSurfaceVariant),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InitialsAvatar(initials(p.displayName)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        name,
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            linked,
                            Pill(last == null ? 'No sessions yet' : 'Last: ${relativeDay(last, now)}', icon: Icons.history),
                            if (rate != null) Pill('7 days: ${(rate * 100).round()}%', icon: Icons.insights),
                            ...attention,
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.onSurfaceVariant),
                ],
              ),
      ),
    );
  }
}
