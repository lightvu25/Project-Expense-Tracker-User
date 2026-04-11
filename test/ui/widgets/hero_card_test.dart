import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_expense_tracker_user/ui/widgets/hero_card.dart';
import 'package:project_expense_tracker_user/ui/theme/app_theme.dart';

void main() {
  group('HeroCard Widget Tests', () {
    Widget createTestWidget({
      required double totalBudget,
      required double totalSpent,
      required double totalRemaining,
      required int activeProjects,
      int totalProjects = 0,
      int completedProjects = 0,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: HeroCard(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalRemaining: totalRemaining,
            activeProjects: activeProjects,
            totalProjects: totalProjects,
            completedProjects: completedProjects,
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('displays Total Budget label', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        expect(find.text('Total Budget'), findsOneWidget);
      });

      testWidgets('displays budget amount formatted', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert: 100000 -> $100k with $ prefix
        expect(find.text('\$100k'), findsOneWidget);
      });

      testWidgets('displays Spent label and amount', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        expect(find.text('Spent'), findsOneWidget);
        expect(
          find.text('\$50k'),
          findsNWidgets(2),
        ); // Budget + Spent both show $50k
      });

      testWidgets('displays Remaining label and amount', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        expect(find.text('Remaining'), findsOneWidget);
        expect(
          find.text('\$50k'),
          findsNWidgets(2),
        ); // Spent and Remaining both show $50k
      });

      testWidgets('displays active projects count', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        expect(find.text('5 Active'), findsOneWidget);
      });

      testWidgets('displays zero when activeProjects is zero', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 0.0,
            totalSpent: 0.0,
            totalRemaining: 0.0,
            activeProjects: 0,
          ),
        );

        // Assert
        expect(find.text('0 Active'), findsOneWidget);
      });
    });

    group('Progress Calculation', () {
      testWidgets('displays progress bar', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('displays progress percentage', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert: 50% spent
        expect(find.text('50% of budget used'), findsOneWidget);
      });

      testWidgets('handles zero budget without crashing', (
        WidgetTester tester,
      ) async {
        // Arrange: Zero budget
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 0.0,
            totalSpent: 0.0,
            totalRemaining: 0.0,
            activeProjects: 0,
          ),
        );

        // Assert: Should show 0%
        expect(find.text('0% of budget used'), findsOneWidget);
      });

      testWidgets('displays 100% when fully spent', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 50000.0,
            totalSpent: 50000.0,
            totalRemaining: 0.0,
            activeProjects: 3,
          ),
        );

        // Assert
        expect(find.text('100% of budget used'), findsOneWidget);
      });
    });

    group('Styling', () {
      testWidgets('has Container with margin', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.margin, isNotNull);
      });

      testWidgets('has gradient decoration', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
      });

      testWidgets('has border radius', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(20));
      });

      testWidgets('has box shadow', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 100000.0,
            totalSpent: 50000.0,
            totalRemaining: 50000.0,
            activeProjects: 5,
          ),
        );

        // Assert
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotEmpty);
      });
    });

    group('Number Formatting', () {
      testWidgets('formats thousands as k', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 50000.0,
            totalSpent: 25000.0,
            totalRemaining: 25000.0,
            activeProjects: 3,
          ),
        );

        // Assert: 50000 -> $50k
        expect(find.text('\$50k'), findsOneWidget);
      });

      testWidgets('formats millions as M', (WidgetTester tester) async {
        // Arrange: Budget over 1 million
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 1500000.0,
            totalSpent: 500000.0,
            totalRemaining: 1000000.0,
            activeProjects: 10,
          ),
        );

        // Assert: 1500000 -> $1.5M
        expect(find.text('\$1.5M'), findsOneWidget);
      });

      testWidgets('formats small numbers without suffix', (
        WidgetTester tester,
      ) async {
        // Arrange: Small budget
        await tester.pumpWidget(
          createTestWidget(
            totalBudget: 500.0,
            totalSpent: 100.0,
            totalRemaining: 400.0,
            activeProjects: 1,
          ),
        );

        // Assert: No 'k' suffix for small numbers, includes $ prefix
        expect(find.text('\$500'), findsOneWidget);
      });
    });
  });
}
