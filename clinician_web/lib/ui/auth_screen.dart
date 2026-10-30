import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:physio_app/branding/logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/errors.dart';
import 'widgets.dart';

/// Email and password sign-in, or a new account (confirmed by email).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});

  final GoTrueClient auth;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final email = _email.text.trim();
    try {
      if (_signUp) {
        final res = await widget.auth.signUp(
          email: email,
          password: _password.text,
          emailRedirectTo: kIsWeb ? Uri.base.origin : null,
        );
        // With confirmation on there is no session yet. An existing address
        // comes back as a user with no identities, so say so plainly.
        if (res.session == null) {
          final exists = res.user?.identities?.isEmpty ?? false;
          setState(() {
            _signUp = false;
            if (exists) {
              _error = 'An account with this email already exists. Sign in instead.';
            } else {
              _info = 'We sent a confirmation link to $email. Open it, then come back here and sign in.';
            }
          });
        }
      } else {
        await widget.auth.signInWithPassword(email: email, password: _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Wordmark(size: 40)),
                const SizedBox(height: 10),
                Text(
                  'Dashboard for physiotherapists',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: c.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                Panel(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('Sign in'), icon: Icon(Icons.login)),
                              ButtonSegment(value: true, label: Text('New account'), icon: Icon(Icons.person_add_alt)),
                            ],
                            selected: {_signUp},
                            showSelectedIcon: false,
                            onSelectionChanged: _busy
                                ? null
                                : (s) => setState(() {
                                    _signUp = s.first;
                                    _error = null;
                                    _info = null;
                                  }),
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            style: theme.textTheme.bodyLarge,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return 'Enter your email.';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'That email does not look right.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            obscureText: !_showPassword,
                            autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _busy ? null : _submit(),
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              helperText: _signUp ? 'At least 8 characters' : null,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _showPassword ? 'Hide password' : 'Show password',
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              ),
                            ),
                            validator: (v) {
                              final s = v ?? '';
                              if (s.isEmpty) return 'Enter your password.';
                              if (_signUp && s.length < 8) return 'Use at least 8 characters.';
                              return null;
                            },
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_error != null) ...[
                                  const SizedBox(height: 18),
                                  Notice(text: _error!, icon: Icons.error_outline, tone: Tone.bad),
                                ],
                                if (_info != null) ...[
                                  const SizedBox(height: 18),
                                  Notice(text: _info!, icon: Icons.mark_email_read_outlined, tone: Tone.good),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                                : Text(_signUp ? 'Create account' : 'Sign in'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Patients use the PhysioSathi phone app with a code from you. This site is only for clinic staff.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
