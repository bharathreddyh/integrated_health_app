import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:integrated_health_app/main.dart';

void main() {
  testWidgets('IHA app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Add your providers here when you create them
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('IHA'),
            ),
          ),
        ),
      ),
    );

    // Verify that our app shows IHA text.
    expect(find.text('IHA'), findsOneWidget);
  });
}