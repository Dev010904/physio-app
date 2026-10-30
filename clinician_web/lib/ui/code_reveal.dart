import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physio_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/text.dart';
import 'widgets.dart';

/// A patient's new access code in big letters, with ways to pass it on.
/// The server keeps only a hash, so this is the one time it can be shown.
class CodeReveal extends StatelessWidget {
  const CodeReveal({super.key, required this.name, required this.code});

  final String name;
  final String code;

  Future<void> _copy(BuildContext context, String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) showMessage(context, '$what copied.');
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showMessage(context, 'Could not open that app. Copy the message instead.', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final message = shareMessage(code);
    final shown = formatAccessCode(code);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Code for $name', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
          decoration: BoxDecoration(
            color: Brand.of(context).soft,
            borderRadius: BorderRadius.circular(Brand.of(context).radius),
            border: Border.all(color: c.primary, width: 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SelectableText(
              shown,
              semanticsLabel: 'Access code ${shown.split('').join(' ')}',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
                color: c.onSurface,
                fontFamily: 'monospace',
                fontFamilyFallback: const ['Roboto Mono', 'Consolas', 'Courier New'],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Notice(
          text: 'Give or send this code now. For privacy it is shown only once. It works for 30 days, on one phone.',
          icon: Icons.visibility_outlined,
          tone: Tone.warn,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(style: compactButton, onPressed: () => _copy(context, shown, 'Code'), icon: const Icon(Icons.copy), label: const Text('Copy code')),
            OutlinedButton.icon(
              style: compactOutlined,
              onPressed: () => _open(context, whatsAppUri(message)),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Send on WhatsApp'),
            ),
            OutlinedButton.icon(style: compactOutlined, onPressed: () => _open(context, smsUri(message)), icon: const Icon(Icons.sms_outlined), label: const Text('Send SMS')),
            OutlinedButton.icon(
              style: compactOutlined,
              onPressed: () => _copy(context, message, 'Message'),
              icon: const Icon(Icons.content_paste),
              label: const Text('Copy message'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Message', style: theme.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Brand.of(context).radius - 4),
          ),
          child: SelectableText(message, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}

/// Shows [code] in a dialog, e.g. after "Reset code".
Future<void> showCodeDialog(BuildContext context, {required String name, required String code}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    content: SizedBox(width: 560, child: SingleChildScrollView(child: CodeReveal(name: name, code: code))),
    actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
    actions: [FilledButton(style: compactButton, onPressed: () => Navigator.pop(context), child: const Text('I have shared it'))],
  ),
);
