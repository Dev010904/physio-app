import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../program/program_controller.dart';
import '../sync/supabase_backend.dart';
import '../theme/app_theme.dart';

/// Links this phone to the patient's physio with the code they were given.
/// Pops with true once the program has downloaded.
class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key, required this.programs});

  final ProgramController programs;

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  final _code = TextEditingController();
  bool _consent = false;
  bool _busy = false;
  String? _error;

  static final _allowed = RegExp('[A-Za-z0-9]');

  String get _cleanCode => _code.text.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
  bool get _ready => _cleanCode.length == 8 && _consent && !_busy;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.programs.linkWithCode(_cleanCode).timeout(const Duration(seconds: 30));
      if (mounted) Navigator.of(context).pop(true);
    } on LinkException catch (e) {
      // The server explains in English; the common case has its own words.
      _fail(e.message.contains('not valid') ? l.errInvalidCode : e.message);
    } on SocketException {
      _fail(l.errNoInternet);
    } on TimeoutException {
      _fail(l.errSlow);
    } catch (e) {
      _fail(l.errGeneric);
    }
  }

  void _fail(String message) {
    if (mounted) {
      setState(() {
        _busy = false;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.linkTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
            child: Icon(Icons.link_rounded, size: 52, color: colors.primary),
          ),
          const SizedBox(height: 20),
          Text(l.enterCode, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            l.codeHelp,
            style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _code,
            autofocus: true,
            enabled: !_busy,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.allow(_allowed), _UpperCase()],
            style: text.headlineMedium?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: 'ABCD2345', counterText: '', border: OutlineInputBorder()),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _ready ? _link() : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: colors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: text.bodyLarge?.copyWith(color: colors.error))),
              ],
            ),
          ],
          const SizedBox(height: 20),
          CheckboxListTile(
            value: _consent,
            onChanged: _busy ? null : (v) => setState(() => _consent = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(l.consent),
            subtitle: Text(l.consentBody),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _ready ? _link : null,
            child: _busy
                ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : Text(l.linkButton),
          ),
        ],
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
