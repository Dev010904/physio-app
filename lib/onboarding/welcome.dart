import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../branding/logo.dart';
import '../theme/app_theme.dart';
import '../tutorials/tutorial.dart';
import '../tutorials/tutorial_view.dart';

/// Whether the first-run welcome has been seen; remembered between launches.
class WelcomeController extends ValueNotifier<bool> {
  WelcomeController({bool seen = false}) : super(seen);

  static const _key = 'welcome_seen';

  static Future<WelcomeController> load() async {
    try {
      return WelcomeController(seen: (await SharedPreferences.getInstance()).getBool(_key) ?? false);
    } catch (_) {
      return WelcomeController();
    }
  }

  Future<void> markSeen() async {
    value = true;
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, true);
    } catch (_) {
      // Not saved; the welcome shows again next launch, which is harmless.
    }
  }
}

/// Three short pages before the first session: what the app is, how to
/// follow a tutorial, and when to stop.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _count = 3;
  bool get _last => _page == _count - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) {
      widget.onDone();
    } else {
      _pages.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = Brand.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 56,
                child: AnimatedOpacity(
                  opacity: _last ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(onPressed: _last ? null : widget.onDone, child: const Text('Skip')),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _Page(
                    visual: LogoMark(size: 132),
                    title: 'Welcome to $appName',
                    body: 'Your home exercises, guided step by step. Everything works without internet.',
                  ),
                  _Page(
                    visual: ClipRRect(
                      borderRadius: BorderRadius.circular(brand.radius + 4),
                      child: ColoredBox(
                        color: brand.soft,
                        child: SizedBox.square(
                          dimension: 280,
                          child: TutorialLoop(tutorial: tutorials['wall_squat']!, cycle: const Duration(seconds: 6)),
                        ),
                      ),
                    ),
                    title: 'Watch, then move along',
                    body:
                        'The video moves with the timer and the voice, rep by rep. '
                        'The glow shows what each exercise does:',
                    extra: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        for (final effect in Effect.values)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [EffectDot(effect), const SizedBox(width: 8), Text(effect.label)],
                          ),
                      ],
                    ),
                  ),
                  _Page(
                    visual: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(color: colors.errorContainer, shape: BoxShape.circle),
                      child: Icon(Icons.health_and_safety_outlined, size: 72, color: colors.onErrorContainer),
                    ),
                    title: 'Exercise safely',
                    body:
                        'Move slowly and stay within comfort. Stop and contact your physiotherapist '
                        'if you feel sharp pain, numbness, or pain above 7 out of 10.',
                  ),
                ],
              ),
            ),
            _Dots(count: _count, index: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _next, child: Text(_last ? 'Get started' : 'Next')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.visual, required this.title, required this.body, this.extra});

  final Widget visual;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Centred in the space, and scrolls if a large font makes it taller.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 290, child: Center(child: visual)),
              const SizedBox(height: 28),
              Text(title, style: text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                body,
                style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (extra != null) ...[const SizedBox(height: 16), extra!],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? colors.primary : colors.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
