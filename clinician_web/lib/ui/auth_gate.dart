import 'dart:async';

import 'package:flutter/material.dart';
import 'package:physio_app/branding/logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../data/clinic_api.dart';
import '../data/models.dart';
import 'auth_screen.dart';
import 'create_clinic_screen.dart';
import 'scope.dart';
import 'shell.dart';
import 'widgets.dart';

/// Signed out → sign in; signed in without a clinic → create one; else the dashboard.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.theme});

  final ThemeController theme;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _client = Supabase.instance.client;
  late final _api = ClinicApi(_client);
  final _changes = DataChanges();
  late final StreamSubscription<AuthState> _sub;
  String? _userId;
  Future<Clinician?>? _profile;

  @override
  void initState() {
    super.initState();
    _setUser(_client.auth.currentUser?.id);
    _sub = _client.auth.onAuthStateChange.listen((state) {
      final id = state.session?.user.id;
      // Token refreshes keep the same user; only a new user reloads the profile.
      if (id != _userId) setState(() => _setUser(id));
    });
  }

  void _setUser(String? id) {
    _userId = id;
    _profile = id == null ? null : _api.me();
  }

  @override
  void dispose() {
    _sub.cancel();
    _changes.dispose();
    super.dispose();
  }

  Future<void> _signOut() => _client.auth.signOut();

  void _reloadProfile() => setState(() => _profile = _api.me());

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (_userId == null) {
      child = AuthScreen(auth: _client.auth);
    } else {
      child = FutureBuilder<Clinician?>(
        key: ValueKey(_profile),
        future: _profile,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: _Splash()));
          }
          if (snap.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ErrorPanel(error: snap.error!, onRetry: _reloadProfile),
                    TextButton(onPressed: _signOut, child: const Text('Sign out')),
                  ],
                ),
              ),
            );
          }
          final me = snap.data;
          if (me == null) {
            return CreateClinicScreen(api: _api, onCreated: _reloadProfile, onSignOut: _signOut);
          }
          return AppScope(
            api: _api,
            clinician: me,
            theme: widget.theme,
            changes: _changes,
            signOut: _signOut,
            child: const Shell(),
          );
        },
      );
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(_userId), child: child));
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [Wordmark(size: 36), SizedBox(height: 24), SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3))],
  );
}
