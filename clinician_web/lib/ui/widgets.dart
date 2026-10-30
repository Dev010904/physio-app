import 'package:flutter/material.dart';
import 'package:physio_app/theme/app_theme.dart';

import '../data/errors.dart';

/// From this width the dashboard shows its sidebar and side-by-side panels.
const wideBreakpoint = 960.0;

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wideBreakpoint;

/// The theme's filled buttons stretch to full width; this one fits its label.
final compactButton = FilledButton.styleFrom(minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: 22));
final compactOutlined = OutlinedButton.styleFrom(minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: 20));

/// A white (or navy) card with an optional heading.
class Panel extends StatelessWidget {
  const Panel({super.key, this.title, this.icon, this.trailing, required this.child, this.padding = const EdgeInsets.all(20)});

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Brand.of(context).radius),
        side: BorderSide(color: c.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[Icon(icon, size: 22, color: c.primary), const SizedBox(width: 10)],
                  Expanded(child: Text(title!, style: Theme.of(context).textTheme.titleMedium)),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

enum Tone { neutral, good, warn, bad, info }

({Color bg, Color fg}) toneColors(BuildContext context, Tone tone) {
  final c = Theme.of(context).colorScheme;
  final dark = c.brightness == Brightness.dark;
  return switch (tone) {
    Tone.good => (bg: c.primaryContainer, fg: c.onPrimaryContainer),
    Tone.bad => (bg: c.errorContainer, fg: c.onErrorContainer),
    Tone.warn => dark ? (bg: const Color(0xFF633806), fg: const Color(0xFFFAEEDA)) : (bg: const Color(0xFFFAEEDA), fg: const Color(0xFF633806)),
    Tone.info => (bg: Brand.of(context).soft, fg: c.onSurface),
    Tone.neutral => (bg: c.surfaceContainerHigh, fg: c.onSurfaceVariant),
  };
}

/// A small rounded label: "Phone linked", "2 open flags".
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.icon, this.tone = Tone.neutral});

  final String label;
  final IconData? icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final t = toneColors(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: t.fg), const SizedBox(width: 5)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.fg, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// A coloured strip with an icon and a sentence, for warnings and tips.
class Notice extends StatelessWidget {
  const Notice({super.key, required this.text, this.icon = Icons.info_outline, this.tone = Tone.info, this.action});

  final String text;
  final IconData icon;
  final Tone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = toneColors(context, tone);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(Brand.of(context).radius - 4)),
      child: Row(
        children: [
          Icon(icon, color: t.fg),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: t.fg))),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(message!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'That did not load',
      message: friendlyError(error),
      action: onRetry == null
          ? null
          : OutlinedButton.icon(style: compactOutlined, onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
    );
  }
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(height: 14),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Loads [load] and shows loading, error (with retry) and data states. It
/// reloads when [refreshOn] rings, keeping the old data on screen meanwhile.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder, this.refreshOn, this.loadingLabel = 'Loading…'});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final Listenable? refreshOn;
  final String loadingLabel;

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  late Future<T> _future = widget.load();
  T? _last;
  bool _hasLast = false;

  @override
  void initState() {
    super.initState();
    widget.refreshOn?.addListener(_reload);
  }

  @override
  void didUpdateWidget(Loader<T> old) {
    super.didUpdateWidget(old);
    if (old.refreshOn != widget.refreshOn) {
      old.refreshOn?.removeListener(_reload);
      widget.refreshOn?.addListener(_reload);
    }
  }

  @override
  void dispose() {
    widget.refreshOn?.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _future = widget.load());
  }

  Future<void> _reloadAndWait() async {
    _reload();
    try {
      await _future;
    } catch (_) {
      // Shown by the builder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done && !snap.hasError) {
          _last = snap.data as T;
          _hasLast = true;
        }
        final Widget child;
        if (snap.hasError && snap.connectionState == ConnectionState.done) {
          child = Center(key: const ValueKey('error'), child: ErrorPanel(error: snap.error!, onRetry: _reload));
        } else if (_hasLast) {
          child = KeyedSubtree(key: const ValueKey('data'), child: widget.builder(context, _last as T, _reloadAndWait));
        } else {
          child = Center(key: const ValueKey('loading'), child: LoadingPanel(label: widget.loadingLabel));
        }
        // The default layout centres a page that is shorter than the screen;
        // fill the space instead, so pages start at the top.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: child,
        );
      },
    );
  }
}

/// A centred, width-limited, scrolling page body.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1180});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final pad = isWide(context) ? 32.0 : 16.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad - 8, pad, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// Page title with a back button when there is somewhere to go back to.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.leading, this.actions = const []});

  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (canPop) ...[
          IconButton.filledTonal(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 14),
        ],
        if (leading != null) ...[leading!, const SizedBox(width: 14)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                DefaultTextStyle.merge(style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant), child: subtitle!),
              ],
            ],
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: LayoutBuilder(
        builder: (context, box) {
          if (actions.isEmpty) return heading;
          if (box.maxWidth >= 720) {
            return Row(children: [Expanded(child: heading), const SizedBox(width: 16), Wrap(spacing: 12, runSpacing: 12, children: actions)]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [heading, const SizedBox(height: 16), Wrap(spacing: 12, runSpacing: 12, children: actions)],
          );
        },
      ),
    );
  }
}

/// Two columns on wide screens, one on narrow; children keep their order
/// down the left column, then the right.
class TwoColumns extends StatelessWidget {
  const TwoColumns({super.key, required this.left, required this.right, this.gap = 20});

  final List<Widget> left;
  final List<Widget> right;
  final double gap;

  @override
  Widget build(BuildContext context) {
    List<Widget> spaced(List<Widget> items) => [
      for (var i = 0; i < items.length; i++) ...[if (i > 0) SizedBox(height: gap), items[i]],
    ];
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 860) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced([...left, ...right]));
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced(left))),
            SizedBox(width: gap),
            Expanded(flex: 9, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced(right))),
          ],
        );
      },
    );
  }
}

/// A round badge with someone's initials.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.text, {super.key, this.size = 44});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
      child: Text(text, style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700, color: c.onSurface)),
    );
  }
}

void showMessage(BuildContext context, String text, {bool error = false}) {
  final c = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle(fontSize: 16, color: error ? c.onErrorContainer : null)),
        backgroundColor: error ? c.errorContainer : null,
        width: 520,
      ),
    );
}

/// A yes/no question; true only when the clinician confirms.
Future<bool> confirm(BuildContext context, {required String title, required Widget body, required String yes, bool danger = false}) async {
  final c = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: SingleChildScrollView(child: body)),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        OutlinedButton(style: compactOutlined, onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: danger ? compactButton.merge(FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: c.onError)) : compactButton,
          onPressed: () => Navigator.pop(context, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return ok ?? false;
}
