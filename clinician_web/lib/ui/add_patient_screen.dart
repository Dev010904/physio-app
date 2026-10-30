import 'package:flutter/material.dart';

import '../data/errors.dart';
import 'code_reveal.dart';
import 'patient_screen.dart';
import 'program_builder_screen.dart';
import 'scope.dart';
import 'shell.dart';
import 'widgets.dart';

/// Name and language in; a one-time access code out.
class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _language = 'en';
  bool _busy = false;
  String? _error;
  ({String patientId, String code, String name})? _created;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final scope = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final name = _name.text.trim();
      final r = await scope.api.createPatient(name: name, language: _language);
      scope.changes.bump();
      setState(() => _created = (patientId: r.patientId, code: r.code, name: name));
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addAnother() => setState(() {
    _created = null;
    _name.clear();
    _language = 'en';
  });

  @override
  Widget build(BuildContext context) {
    final created = _created;
    return PopScope(
      // Leaving would lose the only view of the code, so ask first.
      canPop: created == null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirm(
          context,
          title: 'Leave this page?',
          body: const Text('The code will not be shown again. If it was not shared, you can make a new one with "Reset code" on the patient page.'),
          yes: 'Leave',
        );
        // pop() does not ask PopScope again.
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: PageBody(
          maxWidth: 680,
          children: [
            PageHeader(
              title: created == null ? 'Add a patient' : 'Patient added',
              subtitle: Text(created == null ? 'They get a code to link the PhysioSathi app on their phone.' : '${created.name} is in your patient list.'),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: created == null ? _formPanel(context) : _donePanel(context, created),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Panel(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _busy ? null : _submit(),
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Patient name',
                hintText: 'e.g. Asha Kumar',
                helperText: 'As you want to see it in your list. The patient sees it too.',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Enter the patient’s name.';
                if (s.length > 80) return 'Keep the name under 80 characters.';
                return null;
              },
            ),
            const SizedBox(height: 22),
            Text('App language', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'hi', label: Text('हिन्दी  Hindi')),
              ],
              selected: {_language},
              showSelectedIcon: true,
              onSelectionChanged: (s) => setState(() => _language = s.first),
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              Notice(text: _error!, icon: Icons.error_outline, tone: Tone.bad),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.key_outlined),
              label: const Text('Add patient and get code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _donePanel(BuildContext context, ({String patientId, String code, String name}) created) {
    final nav = Navigator.of(context);
    void openPatient({bool builder = false}) {
      setState(() => _created = null);
      nav.pushReplacement(pageRoute(PatientScreen(patientId: created.patientId, name: created.name), 'patient'));
      if (builder) nav.push(pageRoute(ProgramBuilderScreen(patientId: created.patientId, patientName: created.name), 'builder'));
    }

    return Column(
      key: const ValueKey('done'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(padding: const EdgeInsets.all(24), child: CodeReveal(name: created.name, code: created.code)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              style: compactButton,
              onPressed: () => openPatient(builder: true),
              icon: const Icon(Icons.playlist_add),
              label: const Text('Build their program'),
            ),
            OutlinedButton.icon(style: compactOutlined, onPressed: openPatient, icon: const Icon(Icons.person_outline), label: const Text('Open patient page')),
            TextButton.icon(onPressed: _addAnother, icon: const Icon(Icons.add), label: const Text('Add another patient')),
          ],
        ),
      ],
    );
  }
}
