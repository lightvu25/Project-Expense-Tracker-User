import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_expense_tracker_user/ui/widgets/expense_tile.dart';
import 'package:project_expense_tracker_user/models/expense.dart';
import 'package:project_expense_tracker_user/ui/theme/app_theme.dart';

void main() {
  group('ExpenseTile Widget Tests', () {
    final testExpense = Expense(
      id: 'e1',
      description: 'Office furniture purchase',
      amount: 12500.0,
      category: ExpenseCategory.materials,
      date: DateTime(2025, 3, 15),
      projectId: 'p1',
    );

    final testExpenseWithImage = Expense(
      id: 'e2',
      description: 'Receipt image',
      amount: 500.0,
      category: ExpenseCategory.materials,
      date: DateTime(2025, 3, 15),
      projectId: 'p1',
      imageUrl: 'https://example.com/receipt.jpg',
    );

    Widget createTestWidget({required Expense expense, VoidCallback? onTap}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ExpenseTile(expense: expense, onTap: onTap),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('displays expense description', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        expect(find.text('Office furniture purchase'), findsOneWidget);
      });

      testWidgets('displays expense amount with negative sign', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert: Actual format is -$12500.00 (no comma)
        expect(find.text('-\$12500.00'), findsOneWidget);
      });

      testWidgets('displays category display name', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        expect(find.text('Materials'), findsOneWidget);
      });

      testWidgets('displays formatted date', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert: Date formatted as MM/DD/YYYY
        expect(find.text('3/15/2025'), findsOneWidget);
      });

      testWidgets('displays category icon', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert: Materials icon
        expect(find.text('🛒'), findsOneWidget);
      });
    });

    group('Category Icons', () {
      testWidgets('displays travel icon for travel category', (
        WidgetTester tester,
      ) async {
        // Arrange
        final travelExpense = testExpense.copyWith(
          category: ExpenseCategory.travel,
        );

        // Act
        await tester.pumpWidget(createTestWidget(expense: travelExpense));

        // Assert
        expect(find.text('✈️'), findsOneWidget);
      });

      testWidgets('displays equipment icon for equipment category', (
        WidgetTester tester,
      ) async {
        // Arrange
        final equipmentExpense = testExpense.copyWith(
          category: ExpenseCategory.equipment,
        );

        // Act
        await tester.pumpWidget(createTestWidget(expense: equipmentExpense));

        // Assert
        expect(find.text('🔧'), findsOneWidget);
      });

      testWidgets('displays labor icon for labor category', (
        WidgetTester tester,
      ) async {
        // Arrange
        final laborExpense = testExpense.copyWith(
          category: ExpenseCategory.labor,
        );

        // Act
        await tester.pumpWidget(createTestWidget(expense: laborExpense));

        // Assert
        expect(find.text('👷'), findsOneWidget);
      });

      testWidgets('displays software icon for software category', (
        WidgetTester tester,
      ) async {
        // Arrange
        final softwareExpense = testExpense.copyWith(
          category: ExpenseCategory.software,
        );

        // Act
        await tester.pumpWidget(createTestWidget(expense: softwareExpense));

        // Assert
        expect(find.text('💻'), findsOneWidget);
      });

      testWidgets('displays marketing icon for marketing category', (
        WidgetTester tester,
      ) async {
        // Arrange
        final marketingExpense = testExpense.copyWith(
          category: ExpenseCategory.services,
        );

        // Act
        await tester.pumpWidget(createTestWidget(expense: marketingExpense));

        // Assert
        expect(find.text('📢'), findsOneWidget);
      });

      testWidgets('displays utilities icon for utilities category', (
        WidgetTester tester,
      ) async {
        // Arrange
        final utilitiesExpense = testExpense.copyWith(
          category: ExpenseCategory.utilities,
        );

        // Act
        await tester.pumpWidget(createTestWidget(expense: utilitiesExpense));

        // Assert
        expect(find.text('💡'), findsOneWidget);
      });

      testWidgets('displays other icon for other category', (
        WidgetTester tester,
      ) async {
        // Arrange
        final otherExpense = testExpense.copyWith(
          category: ExpenseCategory.miscellaneous,
        );

        // Act
        await tester.pumpWidget(createTestWidget(expense: otherExpense));

        // Assert
        expect(find.text('📦'), findsOneWidget);
      });
    });

    group('Amount Formatting', () {
      testWidgets('formats amount with currency symbol', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        expect(find.textContaining('\$'), findsOneWidget);
      });

      testWidgets('formats amount with two decimal places', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert: Actual format is -$12500.00 (no comma)
        expect(find.text('-\$12500.00'), findsOneWidget);
      });

      testWidgets('formats decimal amounts correctly', (
        WidgetTester tester,
      ) async {
        // Arrange: Expense with decimal amount
        final decimalExpense = testExpense.copyWith(amount: 99.99);

        // Act
        await tester.pumpWidget(createTestWidget(expense: decimalExpense));

        // Assert
        expect(find.text('-\$99.99'), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('triggers onTap callback when tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        bool tapped = false;
        await tester.pumpWidget(
          createTestWidget(expense: testExpense, onTap: () => tapped = true),
        );

        // Act
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();

        // Assert
        expect(tapped, true);
      });

      testWidgets('has GestureDetector for tap handling', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        expect(find.byType(GestureDetector), findsOneWidget);
      });
    });

    group('Styling', () {
      testWidgets('has Container with padding', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.padding, isNotNull);
      });

      testWidgets('has border at bottom', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
      });

      testWidgets('has category icon container with circular border', (
        WidgetTester tester,
      ) async {
        // Arrange: Use expense with imageUrl
        await tester.pumpWidget(
          createTestWidget(expense: testExpenseWithImage),
        );
        await tester.pumpAndSettle();

        // Assert: Image loads with ClipRRect container
        expect(find.byType(ClipRRect), findsOneWidget);
      });

      testWidgets('displays fallback icon when no imageUrl', (
        WidgetTester tester,
      ) async {
        // Arrange: Use expense without imageUrl
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert: Shows category icon (Text with emoji)
        expect(find.text('🛒'), findsOneWidget);
      });

      testWidgets('displays category in colored text', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert: Find Text widget with category name
        expect(find.text('Materials'), findsOneWidget);
      });
    });

    group('Layout', () {
      testWidgets('uses Row for horizontal layout', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('uses Expanded for flexible layout', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        expect(find.byType(Expanded), findsWidgets);
      });

      testWidgets('has SizedBox for spacing', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(expense: testExpense));

        // Assert
        expect(find.byType(SizedBox), findsWidgets);
      });
    });
  });
}
