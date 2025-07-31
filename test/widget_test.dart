// Test for EBook Flutter App
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachdientudemo/main.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EBookMobileApp());

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // The app should have loaded successfully
    expect(tester.takeException(), isNull);
  });

  testWidgets('Main layout should be present', (WidgetTester tester) async {
    await tester.pumpWidget(const EBookMobileApp());
    await tester.pumpAndSettle();

    // Should find the main scaffold
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });
}
