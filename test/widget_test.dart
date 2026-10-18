import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/app.dart';

void main() {
  testWidgets('status screen shows the app name and offline support', (tester) async {
    await tester.pumpWidget(const PhysioApp());

    expect(find.text(appName), findsOneWidget);
    expect(find.text('Works offline'), findsOneWidget);
  });
}
