import 'package:clinician_web/app.dart';
import 'package:clinician_web/ui/auth_screen.dart';
import 'package:clinician_web/ui/code_reveal.dart';
import 'package:clinician_web/ui/pain_chart.dart';
import 'package:clinician_web/ui/program_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: dashboardTheme(AppTheme.light()),
  home: Scaffold(body: Center(child: SingleChildScrollView(child: child))),
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('NumberStepper snaps to its step and stops at the limits', (tester) async {
    var value = 32;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => NumberStepper(
            label: 'Hold for',
            suffix: 's',
            value: value,
            min: 25,
            max: 40,
            step: 5,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    expect(value, 35);
    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    expect(value, 40);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add)).onPressed, isNull);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Less'));
      await tester.pump();
    }
    expect(value, 25);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove)).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '33');
    await tester.pump();
    expect(value, 33);
  });

  testWidgets('CodeReveal shows the code once, big, with the share text, and copies it', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    await tester.pumpWidget(wrap(const SizedBox(width: 600, child: CodeReveal(name: 'Asha Kumar', code: 'ABCD2345'))));

    expect(find.text('Code for Asha Kumar'), findsOneWidget);
    expect(find.text('ABCD-2345'), findsOneWidget);
    expect(find.textContaining("tap 'Have a code from your physio?'"), findsOneWidget);
    expect(find.textContaining('shown only once'), findsOneWidget);

    await tester.tap(find.text('Copy code'));
    await tester.pump();
    expect(copied, ['ABCD-2345']);
    expect(find.text('Code copied.'), findsOneWidget);

    await tester.tap(find.text('Copy message'));
    await tester.pump();
    expect(copied.last, startsWith('Your PhysioSathi code is ABCD-2345.'));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('PainChart paints and describes itself', (tester) async {
    final from = DateTime(2026, 9, 28);
    final to = DateTime(2026, 10, 25);
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 500,
          child: PainChart(
            from: from,
            to: to,
            points: [(day: DateTime(2026, 10, 1), pain: 6), (day: DateTime(2026, 10, 10), pain: 8), (day: DateTime(2026, 10, 24), pain: 3)],
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Pain chart with 3 scores. Latest 3 out of 10, highest 8.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sign in checks the form before calling the server', (tester) async {
    final auth = GoTrueClient(url: 'http://localhost:1/auth/v1', autoRefreshToken: false);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    await tester.pumpWidget(MaterialApp(theme: dashboardTheme(AppTheme.light()), home: AuthScreen(auth: auth)));

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await tester.tap(find.text('New account'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('That email does not look right.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
