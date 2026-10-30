import 'package:flutter/material.dart';
import 'package:physio_app/branding/logo.dart';

import '../data/clinic_api.dart';
import '../data/errors.dart';
import 'widgets.dart';

/// First sign-in: the clinician names their clinic and becomes its admin.
class CreateClinicScreen extends StatefulWidget {
  const CreateClinicScreen({super.key, required this.api, required this.onCreated, required this.onSignOut});

  final ClinicApi api;
  final VoidCallback onCreated;
  final Future<void> Function() onSignOut;

  @override
  State<CreateClinicScreen> createState() => _CreateClinicScreenState();
}

class _CreateClinicScreenState extends State<CreateClinicScreen> {
  final _form = GlobalKey<FormState>();
  final _clinic = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _clinic.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.createClinic(clinicName: _clinic.text, fullName: _name.text, phone: _phone.text);
      widget.onCreated();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? required(String? v, String what) => (v?.trim().isEmpty ?? true) ? 'Enter $what.' : null;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Wordmark(size: 36)),
                const SizedBox(height: 28),
                Panel(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Create your clinic', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          'One step before you add patients. Your patients see these details in their app.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _clinic,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          style: theme.textTheme.bodyLarge,
                          decoration: const InputDecoration(labelText: 'Clinic name', hintText: 'e.g. Sunrise Physio Care', prefixIcon: Icon(Icons.local_hospital_outlined)),
                          validator: (v) => required(v, 'the clinic name'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          style: theme.textTheme.bodyLarge,
                          decoration: const InputDecoration(labelText: 'Your name', hintText: 'e.g. Dr. Meera Shah', prefixIcon: Icon(Icons.badge_outlined)),
                          validator: (v) => required(v, 'your name'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _busy ? null : _submit(),
                          style: theme.textTheme.bodyLarge,
                          decoration: const InputDecoration(
                            labelText: 'Clinic phone (optional)',
                            hintText: '+91 98765 43210',
                            helperText: 'Shown on the patient’s safety screen, so they can call you.',
                            prefixIcon: Icon(Icons.call_outlined),
                          ),
                          validator: (v) {
                            final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                            if (digits.isNotEmpty && digits.length < 8) return 'That phone number looks too short.';
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 18),
                          Notice(text: _error!, icon: Icons.error_outline, tone: Tone.bad),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                              : const Text('Create clinic'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: TextButton(onPressed: _busy ? null : widget.onSignOut, child: const Text('Sign out'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
