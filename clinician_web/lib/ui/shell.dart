import 'package:flutter/material.dart';
import 'package:physio_app/branding/logo.dart';
import 'package:physio_app/theme/app_theme.dart';

import '../logic/text.dart';
import 'add_patient_screen.dart';
import 'patients_screen.dart';
import 'scope.dart';
import 'widgets.dart';

/// Sidebar plus content on wide screens; a top bar and drawer on narrow ones.
/// Pages open in a nested navigator, so the sidebar stays put.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _nav = GlobalKey<NavigatorState>();
  final _scaffold = GlobalKey<ScaffoldState>();
  late final _observer = _SectionObserver(_section);
  final _section = ValueNotifier('patients');

  @override
  void dispose() {
    _section.dispose();
    super.dispose();
  }

  void _go(String section) {
    _scaffold.currentState?.closeDrawer();
    final nav = _nav.currentState!;
    nav.popUntil((r) => r.isFirst);
    if (section == 'add') nav.push(pageRoute(const AddPatientScreen(), 'add'));
  }

  @override
  Widget build(BuildContext context) {
    final navigator = NavigatorPopHandler(
      onPopWithResult: (_) => _nav.currentState?.maybePop(),
      child: Navigator(
        key: _nav,
        observers: [_observer],
        onGenerateRoute: (_) => pageRoute(const PatientsScreen(), 'patients'),
      ),
    );
    final sidebar = ValueListenableBuilder(
      valueListenable: _section,
      builder: (context, section, _) => _Sidebar(section: section, onGo: _go),
    );
    if (isWide(context)) {
      return Scaffold(
        key: _scaffold,
        body: Row(
          children: [
            SizedBox(width: 272, child: sidebar),
            const VerticalDivider(width: 1),
            Expanded(child: navigator),
          ],
        ),
      );
    }
    return Scaffold(
      key: _scaffold,
      appBar: AppBar(
        title: const Wordmark(size: 26),
        actions: [
          IconButton(tooltip: 'Add patient', onPressed: () => _go('add'), icon: const Icon(Icons.person_add_alt_1)),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(width: 300, child: sidebar),
      body: navigator,
    );
  }
}

Route<T> pageRoute<T>(Widget page, String name) => MaterialPageRoute<T>(builder: (_) => page, settings: RouteSettings(name: name));

/// Keeps the sidebar's highlight on the section of the top page.
class _SectionObserver extends NavigatorObserver {
  _SectionObserver(this.section);

  final ValueNotifier<String> section;

  void _update(Route<dynamic>? top) {
    final name = top?.settings.name;
    if (name == null) return;
    // Patient pages and the program builder belong to "Patients".
    WidgetsBinding.instance.addPostFrameCallback((_) => section.value = name == 'add' ? 'add' : 'patients');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _update(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _update(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _update(newRoute);
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.section, required this.onGo});

  final String section;
  final ValueChanged<String> onGo;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final me = scope.clinician;
    return Material(
      color: c.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(padding: EdgeInsets.only(left: 8), child: Align(alignment: Alignment.centerLeft, child: Wordmark(size: 30))),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Brand.of(context).soft, borderRadius: BorderRadius.circular(Brand.of(context).radius - 4)),
                child: Row(
                  children: [
                    Icon(Icons.local_hospital_outlined, color: c.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(me.clinicName, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _NavItem(icon: Icons.groups_outlined, selectedIcon: Icons.groups, label: 'Patients', selected: section == 'patients', onTap: () => onGo('patients')),
              const SizedBox(height: 6),
              _NavItem(icon: Icons.person_add_alt, selectedIcon: Icons.person_add_alt_1, label: 'Add patient', selected: section == 'add', onTap: () => onGo('add')),
              const Spacer(),
              _ThemePicker(),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  InitialsAvatar(initials(me.fullName), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.fullName, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        Text(me.role == 'admin' ? 'Clinic admin' : 'Physiotherapist', style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: () async {
                      final ok = await confirm(context, title: 'Sign out?', body: const Text('You can sign in again with your email and password.'), yes: 'Sign out');
                      if (ok) await scope.signOut();
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(Brand.of(context).radius - 4);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.primary : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(selected ? selectedIcon : icon, color: selected ? c.onPrimary : c.onSurface),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? c.onPrimary : c.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).theme;
    return ValueListenableBuilder(
      valueListenable: theme,
      builder: (context, mode, _) => SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), tooltip: 'Calm clinic (light)'),
          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), tooltip: 'Match this computer'),
          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), tooltip: 'Bold focus (dark)'),
        ],
        selected: {mode},
        onSelectionChanged: (s) => theme.mode = s.first,
      ),
    );
  }
}
