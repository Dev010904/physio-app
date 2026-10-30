import 'package:flutter/widgets.dart';

import '../app.dart';
import '../data/clinic_api.dart';
import '../data/models.dart';

/// Rings when patients, programs or flags change, so open screens reload.
class DataChanges extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// What every signed-in screen needs: the server, who is signed in, and the theme.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.api,
    required this.clinician,
    required this.theme,
    required this.changes,
    required this.signOut,
    required super.child,
  });

  final ClinicApi api;
  final Clinician clinician;
  final ThemeController theme;
  final DataChanges changes;
  final Future<void> Function() signOut;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) => old.clinician != clinician || old.api != api;
}
