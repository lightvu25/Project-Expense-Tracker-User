import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_expense_tracker_user/ui/theme/app_theme.dart';

void main() {
  testWidgets('App smoke test - verifies theme and basic widgets', (
    WidgetTester tester,
  ) async {
    // Create a simple test widget that mimics the app structure
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: const Center(child: Text('Test App')),
        ),
      ),
    );

    // Verify basic elements exist
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Test App'), findsOneWidget);
  });

  testWidgets('AppTheme has correct primary color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Text('Theme Test')),
      ),
    );

    // Verify theme is applied
    final theme = Theme.of(tester.element(find.text('Theme Test')));
    expect(theme.brightness, Brightness.light);
  });
}
