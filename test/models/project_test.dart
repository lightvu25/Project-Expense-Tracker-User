import 'package:flutter_test/flutter_test.dart';
import 'package:project_expense_tracker_user/models/project.dart';
import 'package:project_expense_tracker_user/models/expense.dart';

void main() {
  group('Project Model Tests', () {
    group('fromMap - Date Parsing', () {
      test('fromMap_standardInput_parsesIso8601Date', () {
        // Arrange: Standard map with ISO-8601 date format
        final map = {
          'id': 'p1',
          'name': 'Office Renovation',
          'description': 'Complete renovation',
          'budget': 85000.0,
          'spent': 52300.0,
          'startDate': '2025-03-01T00:00:00.000',
          'endDate': '2025-08-15T00:00:00.000',
          'isActive': 1,
        };

        // Act: Parse the map to Project
        final project = Project.fromMap(map);

        // Assert: Dates parsed correctly
        expect(project.startDate.year, 2025);
        expect(project.startDate.month, 3);
        expect(project.startDate.day, 1);
      });

      test('fromMap_ddMMyyyyDateFormat_parsesWithoutCrashing', () {
        // Arrange: Map with dd/MM/yyyy date format
        final map = {
          'id': 'p2',
          'name': 'Marketing Campaign',
          'description': 'Q2 marketing',
          'budget': 45000.0,
          'spent': 38200.0,
          'startDate': '01/04/2025',
          'endDate': '30/06/2025',
          'isActive': 1,
        };

        // Act: Parse should not throw exception
        final project = Project.fromMap(map);

        // Assert: Date parsed correctly
        expect(project.startDate.day, 1);
        expect(project.startDate.month, 4);
        expect(project.startDate.year, 2025);
        expect(project.endDate?.day, 30);
        expect(project.endDate?.month, 6);
      });

      test('fromMap_nullStartDate_fallsBackToNow', () {
        // Arrange: Map with null start date
        final map = {
          'id': 'p3',
          'name': 'Test Project',
          'description': 'Test',
          'budget': 10000.0,
          'spent': 0.0,
          'startDate': null,
          'isActive': 1,
        };

        // Act: Parse should not throw
        final project = Project.fromMap(map);

        // Assert: Falls back to current date (within reasonable range)
        expect(project.startDate, isNotNull);
        expect(project.startDate.year, DateTime.now().year);
      });

      test('fromMap_invalidDateFormat_fallsBackToNow', () {
        // Arrange: Map with invalid date format
        final map = {
          'id': 'p4',
          'name': 'Test',
          'description': 'Test',
          'budget': 10000.0,
          'spent': 0.0,
          'startDate': 'invalid-date-format',
          'isActive': 1,
        };

        // Act
        final project = Project.fromMap(map);

        // Assert: Falls back to current date
        expect(project.startDate.year, DateTime.now().year);
      });
    });

    group('fromMap - Field Fallbacks', () {
      test('fromMap_spentFallbackToZero_whenNull', () {
        // Arrange: Map without 'spent' field
        final map = {
          'id': 'p1',
          'name': 'Test Project',
          'description': 'Test description',
          'budget': 50000.0,
          'spent': null,
          'startDate': '2025-01-01',
          'isActive': 1,
        };

        // Act
        final project = Project.fromMap(map);

        // Assert: spent defaults to 0.0
        expect(project.spent, 0.0);
        expect(project.remaining, 50000.0);
      });

      test('fromMap_spentFallbackToZero_whenMissing', () {
        // Arrange: Map missing 'spent' key entirely
        final map = {
          'id': 'p1',
          'name': 'Test Project',
          'description': 'Test description',
          'budget': 50000.0,
          'startDate': '2025-01-01',
          'isActive': 1,
        };

        // Act
        final project = Project.fromMap(map);

        // Assert: spent defaults to 0.0
        expect(project.spent, 0.0);
      });

      test('fromMap_budgetFallbackToZero_whenNull', () {
        // Arrange: Map with null budget
        final map = {
          'id': 'p1',
          'name': 'Test Project',
          'description': 'Test',
          'budget': null,
          'spent': 1000.0,
          'startDate': '2025-01-01',
          'isActive': 1,
        };

        // Act
        final project = Project.fromMap(map);

        // Assert: budget defaults to 0.0
        expect(project.budget, 0.0);
      });

      test('fromMap_missingFields_useDefaults', () {
        // Arrange: Minimal map with only required fields
        final map = {'id': 'p1', 'name': 'Minimal Project'};

        // Act
        final project = Project.fromMap(map);

        // Assert: All optional fields have defaults
        expect(project.description, '');
        expect(project.budget, 0.0);
        expect(project.spent, 0.0);
        expect(project.isActive, true); // default
        expect(project.expenses, isEmpty);
        expect(project.isFavorite, false);
      });
    });

    group('fromMap - Java Status Field Handling', () {
      test('fromMap_javaStatusField_mapsCompletedToFalse', () {
        // Arrange: Java sends 'status' = 'Completed'
        final map = {
          'id': 'p1',
          'name': 'Completed Project',
          'description': 'Done',
          'budget': 10000.0,
          'spent': 10000.0,
          'startDate': '2025-01-01',
          'status': 'Completed',
        };

        // Act
        final project = Project.fromMap(map);

        // Assert: isActive is false when status is 'Completed'
        expect(project.isActive, false);
      });

      test('fromMap_javaStatusField_mapsActiveToTrue', () {
        // Arrange: Java sends 'status' = 'Active'
        final map = {
          'id': 'p1',
          'name': 'Active Project',
          'description': 'In Progress',
          'budget': 10000.0,
          'spent': 5000.0,
          'startDate': '2025-01-01',
          'status': 'Active',
        };

        // Act
        final project = Project.fromMap(map);

        // Assert: isActive is true when status is not 'Completed'
        expect(project.isActive, true);
      });

      test('fromMap_isActive_asInteger_one', () {
        // Arrange: isActive as integer 1
        final map = {
          'id': 'p1',
          'name': 'Test',
          'description': 'Test',
          'budget': 10000.0,
          'spent': 0.0,
          'startDate': '2025-01-01',
          'isActive': 1,
        };

        // Act
        final project = Project.fromMap(map);

        expect(project.isActive, true);
      });

      test('fromMap_isActive_asInteger_zero', () {
        // Arrange: isActive as integer 0
        final map = {
          'id': 'p1',
          'name': 'Test',
          'description': 'Test',
          'budget': 10000.0,
          'spent': 0.0,
          'startDate': '2025-01-01',
          'isActive': 0,
        };

        // Act
        final project = Project.fromMap(map);

        expect(project.isActive, false);
      });

      test('fromMap_isActive_asBoolean_true', () {
        // Arrange: isActive as boolean true
        final map = {
          'id': 'p1',
          'name': 'Test',
          'description': 'Test',
          'budget': 10000.0,
          'spent': 0.0,
          'startDate': '2025-01-01',
          'isActive': true,
        };

        // Act
        final project = Project.fromMap(map);

        expect(project.isActive, true);
      });
    });

    group('toMap - Serialization', () {
      test('toMap_standardOutput_producesCorrectJson', () {
        // Arrange: Create a Project with known values
        final project = Project(
          id: 'p1',
          name: 'Test Project',
          description: 'Test Description',
          budget: 50000.0,
          spent: 25000.0,
          startDate: DateTime(2025, 1, 15),
          endDate: DateTime(2025, 6, 30),
          isActive: true,
          expenses: [],
          isFavorite: false,
        );

        // Act: Convert to Map
        final map = project.toMap();

        // Assert: Verify structure and values
        expect(map['id'], 'p1');
        expect(map['name'], 'Test Project');
        expect(map['description'], 'Test Description');
        expect(map['budget'], 50000.0);
        expect(map['spent'], 25000.0);
        expect(map['isActive'], 1); // true → 1
        expect(map.containsKey('startDate'), true);
        expect(map.containsKey('endDate'), true);
      });

      test('toMap_inactiveProject_producesZero', () {
        // Arrange: Inactive project
        final project = Project(
          id: 'p1',
          name: 'Closed Project',
          description: 'Done',
          budget: 10000.0,
          spent: 10000.0,
          startDate: DateTime(2025, 1, 1),
          isActive: false,
          expenses: [],
        );

        // Act
        final map = project.toMap();

        // Assert: isActive = 0 for false
        expect(map['isActive'], 0);
      });
    });

    group('toJson - Integration', () {
      test('toJson_integration_serializesAndDeserializes', () {
        // Arrange: Original project
        final original = Project(
          id: 'p1',
          name: 'Integration Test',
          description: 'Testing roundtrip',
          budget: 75000.0,
          spent: 30000.0,
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 9, 30),
          isActive: true,
          expenses: [
            Expense(
              id: 'e1',
              description: 'Initial expense',
              amount: 5000.0,
              category: ExpenseCategory.materials,
              date: DateTime(2025, 3, 15),
              projectId: 'p1',
            ),
          ],
          isFavorite: true,
        );

        // Act: Serialize to JSON, then deserialize back
        final json = original.toJson();
        final restored = Project.fromJson(json);

        // Assert: All fields preserved
        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.description, original.description);
        expect(restored.budget, original.budget);
        expect(restored.spent, original.spent);
        expect(restored.isActive, original.isActive);
        expect(restored.isFavorite, original.isFavorite);
        expect(restored.expenses.length, 1);
        expect(restored.expenses[0].description, 'Initial expense');
      });
    });

    group('Computed Properties', () {
      test('progress_calculation_normalBudget', () {
        // Arrange: budget = 10000, spent = 2500
        final project = Project(
          id: 'p1',
          name: 'Test',
          description: 'Test',
          budget: 10000.0,
          spent: 2500.0,
          startDate: DateTime.now(),
          isActive: true,
          expenses: [],
        );

        // Act
        final progress = project.progress;

        // Assert: progress = spent / budget = 0.25
        expect(progress, 0.25);
      });

      test('progress_calculation_zeroBudget_doesNotThrow', () {
        // Arrange: budget = 0 (edge case)
        final project = Project(
          id: 'p1',
          name: 'Test',
          description: 'Test',
          budget: 0.0,
          spent: 0.0,
          startDate: DateTime.now(),
          isActive: true,
          expenses: [],
        );

        // Act & Assert: Should not throw division by zero
        expect(() => project.progress, returnsNormally);
        expect(project.progress, 0.0);
      });

      test('progress_calculation_fullBudget', () {
        // Arrange: spent equals budget
        final project = Project(
          id: 'p1',
          name: 'Test',
          description: 'Test',
          budget: 10000.0,
          spent: 10000.0,
          startDate: DateTime.now(),
          isActive: true,
          expenses: [],
        );

        expect(project.progress, 1.0);
      });

      test('progress_calculation_overBudget', () {
        // Arrange: spent exceeds budget
        final project = Project(
          id: 'p1',
          name: 'Test',
          description: 'Test',
          budget: 10000.0,
          spent: 15000.0,
          startDate: DateTime.now(),
          isActive: true,
          expenses: [],
        );

        expect(project.progress, 1.5);
      });

      test('remaining_calculation_normal', () {
        // Arrange: budget = 10000, spent = 3500
        final project = Project(
          id: 'p1',
          name: 'Test',
          description: 'Test',
          budget: 10000.0,
          spent: 3500.0,
          startDate: DateTime.now(),
          isActive: true,
          expenses: [],
        );

        // Act
        final remaining = project.remaining;

        // Assert: remaining = budget - spent = 6500
        expect(remaining, 6500.0);
      });

      test('remaining_calculation_zeroSpent', () {
        // Arrange: spent = 0
        final project = Project(
          id: 'p1',
          name: 'Test',
          description: 'Test',
          budget: 10000.0,
          spent: 0.0,
          startDate: DateTime.now(),
          isActive: true,
          expenses: [],
        );

        expect(project.remaining, 10000.0);
      });
    });

    group('copyWith', () {
      test('copyWith_modification_updatesSpecificFields', () {
        // Arrange: Original project
        final original = Project(
          id: 'p1',
          name: 'Original Name',
          description: 'Original Description',
          budget: 10000.0,
          spent: 5000.0,
          startDate: DateTime(2025, 1, 1),
          isActive: true,
          expenses: [],
          isFavorite: false,
        );

        // Act: Update name and isFavorite
        final modified = original.copyWith(
          name: 'Updated Name',
          isFavorite: true,
        );

        // Assert: Only specified fields changed
        expect(modified.name, 'Updated Name');
        expect(modified.isFavorite, true);
        expect(modified.id, original.id);
        expect(modified.description, original.description);
        expect(modified.budget, original.budget);
        expect(modified.spent, original.spent);
      });

      test('copyWith_noArguments_returnsEquivalent', () {
        // Arrange
        final original = Project(
          id: 'p1',
          name: 'Test',
          description: 'Test',
          budget: 10000.0,
          spent: 5000.0,
          startDate: DateTime(2025, 1, 1),
          isActive: true,
          expenses: [],
        );

        // Act: copyWith with no arguments
        final copy = original.copyWith();

        // Assert: All fields same
        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.budget, original.budget);
        expect(copy.spent, original.spent);
        expect(copy.isActive, original.isActive);
      });
    });
  });
}
