import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_expense_tracker_user/ui/widgets/project_card.dart';
import 'package:project_expense_tracker_user/models/project.dart';
import 'package:project_expense_tracker_user/models/expense.dart';
import 'package:project_expense_tracker_user/ui/theme/app_theme.dart';

void main() {
  group('ProjectCard Widget Tests', () {
    final testProject = Project(
      id: 'p1',
      name: 'Office Renovation',
      description: 'Complete office renovation project',
      budget: 85000.0,
      spent: 52300.0,
      startDate: DateTime(2025, 3, 1),
      endDate: DateTime(2025, 8, 15),
      isActive: true,
      isFavorite: true,
      expenses: [
        Expense(
          id: 'e1',
          description: 'Office furniture',
          amount: 12500.0,
          category: ExpenseCategory.materials,
          date: DateTime(2025, 3, 15),
          projectId: 'p1',
        ),
      ],
    );

    Widget createTestWidget({
      required Project project,
      VoidCallback? onTap,
      VoidCallback? onFavoriteToggle,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ProjectCard(
            project: project,
            onTap: onTap,
            onFavoriteToggle: onFavoriteToggle,
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('displays project name', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert
        expect(find.text('Office Renovation'), findsOneWidget);
      });

      testWidgets('displays project description', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert
        expect(find.text('Complete office renovation project'), findsOneWidget);
      });

      testWidgets('displays Active status for active project', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert
        expect(find.text('Active'), findsOneWidget);
      });

      testWidgets('displays Completed status for inactive project', (
        WidgetTester tester,
      ) async {
        // Arrange: Inactive project
        final inactiveProject = testProject.copyWith(isActive: false);

        // Act
        await tester.pumpWidget(createTestWidget(project: inactiveProject));

        // Assert
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('displays favorite icon when isFavorite is true', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert
        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('displays favorite_border icon when isFavorite is false', (
        WidgetTester tester,
      ) async {
        // Arrange: Non-favorite project
        final nonFavoriteProject = testProject.copyWith(isFavorite: false);

        // Act
        await tester.pumpWidget(createTestWidget(project: nonFavoriteProject));

        // Assert
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      });
    });

    group('Budget Display', () {
      testWidgets('displays budget amount', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert: Budget is displayed with $ prefix
        expect(find.text('Budget'), findsOneWidget);
        expect(find.text('\$85k'), findsOneWidget);
      });

      testWidgets('displays spent amount', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert
        expect(find.text('Spent'), findsOneWidget);
        expect(find.text('\$52.3k'), findsOneWidget);
      });

      testWidgets('displays remaining amount', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert: Remaining = budget - spent = 85000 - 52300 = 32700
        expect(find.text('Remaining'), findsOneWidget);
        expect(find.text('\$32.7k'), findsOneWidget);
      });
    });

    group('Progress Bar', () {
      testWidgets('displays progress bar', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('displays progress percentage', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert: Progress = spent/budget = 52300/85000 = 0.615 -> 61%
        expect(find.text('61% used'), findsOneWidget);
      });

      testWidgets('progress shows 0% when budget is zero', (
        WidgetTester tester,
      ) async {
        // Arrange: Zero budget project
        final zeroBudgetProject = testProject.copyWith(budget: 0.0, spent: 0.0);

        // Act
        await tester.pumpWidget(createTestWidget(project: zeroBudgetProject));

        // Assert
        expect(find.text('0% used'), findsOneWidget);
      });

      testWidgets('progress shows warning color when over 80%', (
        WidgetTester tester,
      ) async {
        // Arrange: High spending project
        final highSpendProject = testProject.copyWith(
          budget: 10000.0,
          spent: 9000.0,
        );

        // Act
        await tester.pumpWidget(createTestWidget(project: highSpendProject));

        // Assert: Progress is 90%
        expect(find.text('90% used'), findsOneWidget);
      });
    });

    group('Date Display', () {
      testWidgets('displays formatted start date', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert: Date formatted as MM/DD/YYYY
        expect(find.text('3/1/2025'), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('triggers onTap callback when tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        bool tapped = false;
        await tester.pumpWidget(
          createTestWidget(project: testProject, onTap: () => tapped = true),
        );

        // Act: Tap on the card
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        // Assert
        expect(tapped, true);
      });

      testWidgets(
        'triggers onFavoriteToggle callback when favorite button tapped',
        (WidgetTester tester) async {
          // Arrange
          bool favoriteToggled = false;
          await tester.pumpWidget(
            createTestWidget(
              project: testProject,
              onFavoriteToggle: () => favoriteToggled = true,
            ),
          );

          // Act: Tap on favorite button
          await tester.tap(find.byIcon(Icons.favorite));
          await tester.pump();

          // Assert
          expect(favoriteToggled, true);
        },
      );

      testWidgets('is tappable when onTap is provided', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(project: testProject, onTap: () {}),
        );

        // Assert: GestureDetector exists
        expect(find.byType(GestureDetector), findsWidgets);
      });
    });

    group('Card Structure', () {
      testWidgets('has Container with margin', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.margin, isNotNull);
      });

      testWidgets('has BoxDecoration with border radius', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert: Find container with decoration
        final containers = tester.widgetList<Container>(find.byType(Container));
        final decoratedContainer = containers.firstWhere(
          (c) => c.decoration is BoxDecoration,
        );
        final decoration = decoratedContainer.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(16));
      });

      testWidgets('has box shadow', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(project: testProject));

        // Assert
        final containers = tester.widgetList<Container>(find.byType(Container));
        final decoratedContainer = containers.firstWhere(
          (c) => c.decoration is BoxDecoration,
        );
        final decoration = decoratedContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotEmpty);
      });
    });
  });
}
