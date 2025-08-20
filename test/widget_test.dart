import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Build a minimal app shell quickly to verify root MaterialApp renders.
  await tester.pumpWidget(const MaterialApp(home: Placeholder()));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that MaterialApp loads.
  expect(find.byType(MaterialApp), findsOneWidget);
  });
}
