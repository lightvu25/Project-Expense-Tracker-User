import 'package:flutter_test/flutter_test.dart';
import 'package:project_expense_tracker_user/models/expense.dart';

void main() {
  group('Expense Model Tests', () {
    group('fromMap - Field Mapping', () {
      test('fromMap_titleToDescription_mapsJavaTitleField', () {
        // Arrange: Java sends 'title' but we use 'description'
        final map = {
          'id': 'e1',
          'title': 'Office furniture purchase',
          'amount': 12500.0,
          'category': 'materials',
          'date': '2025-03-15',
          'projectId': 'p1',
        };

        // Act: Parse the map
        final expense = Expense.fromMap(map);

        // Assert: title maps to description
        expect(expense.description, 'Office furniture purchase');
      });

      test('fromMap_descriptionTakesPriorityOverTitle', () {
        // Arrange: Both 'title' and 'description' present (description should win)
        final map = {
          'id': 'e1',
          'title': 'Java Title',
          'description': 'Dart Description',
          'amount': 1000.0,
          'category': 'labor',
          'date': '2025-03-15',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: description takes priority
        expect(expense.description, 'Dart Description');
      });

      test('fromMap_typeToCategory_mapsJavaTypeField', () {
        // Arrange: Java sends 'type' but we use 'category'
        final map = {
          'id': 'e1',
          'description': 'Travel expense',
          'amount': 500.0,
          'type': 'travel',
          'date': '2025-04-01',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: type maps to category
        expect(expense.category, ExpenseCategory.travel);
      });

      test('fromMap_categoryTakesPriorityOverType', () {
        // Arrange: Both 'type' and 'category' present
        final map = {
          'id': 'e1',
          'description': 'Test',
          'amount': 100.0,
          'type': 'travel',
          'category': 'equipment',
          'date': '2025-04-01',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: category takes priority
        expect(expense.category, ExpenseCategory.equipment);
      });

      test('fromMap_missingDescription_fallsBackToUntitled', () {
        // Arrange: No title or description
        final map = {
          'id': 'e1',
          'amount': 100.0,
          'category': 'other',
          'date': '2025-01-01',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: Falls back to 'Untitled'
        expect(expense.description, 'Untitled');
      });
    });

    group('fromMap - Date Parsing', () {
      test('fromMap_iso8601DateFormat_parsesCorrectly', () {
        // Arrange: ISO-8601 format
        final map = {
          'id': 'e1',
          'description': 'Test expense',
          'amount': 1000.0,
          'category': 'materials',
          'date': '2025-03-15T10:30:00.000',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: Date parsed correctly
        expect(expense.date.year, 2025);
        expect(expense.date.month, 3);
        expect(expense.date.day, 15);
      });

      test('fromMap_ddMMyyyyDateFormat_parsesWithoutCrashing', () {
        // Arrange: dd/MM/yyyy format
        final map = {
          'id': 'e1',
          'description': 'Test expense',
          'amount': 1000.0,
          'category': 'materials',
          'date': '15/03/2025',
          'projectId': 'p1',
        };

        // Act: Should not throw
        final expense = Expense.fromMap(map);

        // Assert: Date parsed correctly
        expect(expense.date.day, 15);
        expect(expense.date.month, 3);
        expect(expense.date.year, 2025);
      });

      test('fromMap_nullDate_fallsBackToNow', () {
        // Arrange: null date
        final map = {
          'id': 'e1',
          'description': 'Test',
          'amount': 100.0,
          'category': 'other',
          'date': null,
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: Falls back to current date
        expect(expense.date.year, DateTime.now().year);
        expect(expense.date.month, DateTime.now().month);
      });

      test('fromMap_invalidDateFormat_fallsBackToNow', () {
        // Arrange: Invalid date string
        final map = {
          'id': 'e1',
          'description': 'Test',
          'amount': 100.0,
          'category': 'other',
          'date': 'not-a-date',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: Falls back to current date
        expect(expense.date.year, DateTime.now().year);
      });
    });

    group('fromMap - Field Fallbacks', () {
      test('fromMap_categoryFallback_unknownString', () {
        // Arrange: Unknown category string
        final map = {
          'id': 'e1',
          'description': 'Test',
          'amount': 100.0,
          'category': 'unknown_category_xyz',
          'date': '2025-01-01',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: Falls back to 'other'
        expect(expense.category, ExpenseCategory.miscellaneous);
      });

      test('fromMap_emptyCategoryString_fallsToOther', () {
        // Arrange: Empty category string
        final map = {
          'id': 'e1',
          'description': 'Test',
          'amount': 100.0,
          'category': '',
          'date': '2025-01-01',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        expect(expense.category, ExpenseCategory.miscellaneous);
      });

      test('fromMap_amountFallback_nullValue', () {
        // Arrange: null amount
        final map = {
          'id': 'e1',
          'description': 'Test',
          'amount': null,
          'category': 'materials',
          'date': '2025-01-01',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        // Assert: amount defaults to 0.0
        expect(expense.amount, 0.0);
      });

      test('fromMap_amountFallback_missingKey', () {
        // Arrange: No amount key
        final map = {
          'id': 'e1',
          'description': 'Test',
          'category': 'materials',
          'date': '2025-01-01',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        expect(expense.amount, 0.0);
      });

      test('fromMap_emptyMap_handlesGracefully', () {
        // Arrange: Completely empty map
        final map = <String, dynamic>{};

        // Act: Should not throw
        final expense = Expense.fromMap(map);

        // Assert: All fields have defaults
        expect(expense.id, '');
        expect(expense.description, 'Untitled');
        expect(expense.amount, 0.0);
        expect(expense.category, ExpenseCategory.miscellaneous);
        expect(expense.projectId, '');
      });

      test('fromMap_idFallback_emptyString', () {
        // Arrange: No id field
        final map = {
          'description': 'Test',
          'amount': 100.0,
          'category': 'materials',
          'date': '2025-01-01',
          'projectId': 'p1',
        };

        // Act
        final expense = Expense.fromMap(map);

        expect(expense.id, '');
      });

      test('fromMap_projectIdFallback_emptyString', () {
        // Arrange: No projectId field
        final map = {
          'id': 'e1',
          'description': 'Test',
          'amount': 100.0,
          'category': 'materials',
          'date': '2025-01-01',
        };

        // Act
        final expense = Expense.fromMap(map);

        expect(expense.projectId, '');
      });
    });

    group('ExpenseCategoryExtension Tests', () {
      test('categoryExtension_allDisplayNames_correct', () {
        // Assert: All 9 categories have correct display names
        expect(ExpenseCategory.materials.displayName, 'Materials');
        expect(ExpenseCategory.travel.displayName, 'Travel');
        expect(ExpenseCategory.equipment.displayName, 'Equipment');
        expect(ExpenseCategory.labor.displayName, 'Labor');
        expect(ExpenseCategory.software.displayName, 'Software');
        expect(ExpenseCategory.services.displayName, 'Marketing');
        expect(ExpenseCategory.utilities.displayName, 'Utilities');
        expect(ExpenseCategory.miscellaneous.displayName, 'Other');
      });

      test('categoryExtension_allIcons_correct', () {
        // Assert: All categories have emoji icons
        expect(ExpenseCategory.materials.icon, '🛒');
        expect(ExpenseCategory.travel.icon, '✈️');
        expect(ExpenseCategory.equipment.icon, '🔧');
        expect(ExpenseCategory.labor.icon, '👷');
        expect(ExpenseCategory.software.icon, '💻');
        expect(ExpenseCategory.services.icon, '📢');
        expect(ExpenseCategory.utilities.icon, '💡');
        expect(ExpenseCategory.miscellaneous.icon, '📦');
      });

      test('categoryExtension_fromString_parsesCorrectly', () {
        // Assert: fromString parses all category names
        expect(
          ExpenseCategoryExtension.fromString('materials'),
          ExpenseCategory.materials,
        );
        expect(
          ExpenseCategoryExtension.fromString('travel'),
          ExpenseCategory.travel,
        );
        expect(
          ExpenseCategoryExtension.fromString('equipment'),
          ExpenseCategory.equipment,
        );
        expect(
          ExpenseCategoryExtension.fromString('labor'),
          ExpenseCategory.labor,
        );
        expect(
          ExpenseCategoryExtension.fromString('software'),
          ExpenseCategory.software,
        );
        expect(
          ExpenseCategoryExtension.fromString('marketing'),
          ExpenseCategory.services,
        );
        expect(
          ExpenseCategoryExtension.fromString('utilities'),
          ExpenseCategory.utilities,
        );
        expect(
          ExpenseCategoryExtension.fromString('other'),
          ExpenseCategory.miscellaneous,
        );
      });

      test('categoryExtension_fromString_caseSensitive', () {
        // Assert: fromString is case-sensitive
        expect(
          ExpenseCategoryExtension.fromString('MATERIALS'),
          ExpenseCategory.miscellaneous,
        );
        expect(
          ExpenseCategoryExtension.fromString('Materials'),
          ExpenseCategory.miscellaneous,
        );
      });

      test('categoryExtension_fromString_unknownValue_fallsToOther', () {
        // Assert: Unknown value falls to 'other'
        expect(
          ExpenseCategoryExtension.fromString('invalid'),
          ExpenseCategory.miscellaneous,
        );
        expect(
          ExpenseCategoryExtension.fromString(''),
          ExpenseCategory.miscellaneous,
        );
      });
    });

    group('toMap - Serialization', () {
      test('toMap_standardOutput_producesCorrectJson', () {
        // Arrange: Create expense with known values
        final expense = Expense(
          id: 'e1',
          date: DateTime(2025, 3, 15),
          amount: 12500.0,
          currency: 'USD',
          category: ExpenseCategory.materials,
          paymentMethod: 'Cash',
          claimant: 'test@example.com',
          paymentStatus: 'Pending',
          description: 'Office furniture',
          projectId: 'p1',
        );

        // Act: Convert to Map
        final map = expense.toMap();

        // Assert: Verify structure and values
        expect(map['id'], 'e1');
        expect(map['description'], 'Office furniture');
        expect(map['amount'], 12500.0);
        expect(map['category'], 'materials');
        expect(map['projectId'], 'p1');
        expect(map.containsKey('date'), true);
      });

      test('toMap_includesDateAsIso8601', () {
        // Arrange
        final expense = Expense(
          id: 'e1',
          date: DateTime(2025, 6, 15, 10, 30),
          amount: 100.0,
          currency: 'USD',
          category: ExpenseCategory.miscellaneous,
          paymentMethod: 'Cash',
          claimant: 'test@example.com',
          paymentStatus: 'Pending',
          description: 'Test',
          projectId: 'p1',
        );

        // Act
        final map = expense.toMap();

        // Assert: Date is in ISO-8601 format
        expect(map['date'], contains('2025-06-15'));
      });
    });

    group('copyWith', () {
      test('copyWith_modification_updatesSpecificFields', () {
        // Arrange: Original expense
        final original = Expense(
          id: 'e1',
          description: 'Original description',
          amount: 1000.0,
          category: ExpenseCategory.materials,
          date: DateTime(2025, 1, 15),
          projectId: 'p1',
        );

        // Act: Update amount and category
        final modified = original.copyWith(
          amount: 2000.0,
          category: ExpenseCategory.equipment,
        );

        // Assert: Only specified fields changed
        expect(modified.amount, 2000.0);
        expect(modified.category, ExpenseCategory.equipment);
        expect(modified.id, original.id);
        expect(modified.description, original.description);
        expect(modified.date, original.date);
        expect(modified.projectId, original.projectId);
      });

      test('copyWith_noArguments_returnsEquivalent', () {
        // Arrange
        final original = Expense(
          id: 'e1',
          description: 'Test',
          amount: 100.0,
          category: ExpenseCategory.labor,
          date: DateTime(2025, 1, 1),
          projectId: 'p1',
        );

        // Act: copyWith with no arguments
        final copy = original.copyWith();

        // Assert: All fields same
        expect(copy.id, original.id);
        expect(copy.description, original.description);
        expect(copy.amount, original.amount);
        expect(copy.category, original.category);
        expect(copy.projectId, original.projectId);
      });

      test('copyWith_allFieldsCanBeModified', () {
        // Arrange
        final original = Expense(
          id: 'e1',
          description: 'Test',
          amount: 100.0,
          category: ExpenseCategory.miscellaneous,
          date: DateTime(2025, 1, 1),
          projectId: 'p1',
        );

        // Act: Modify all fields
        final modified = original.copyWith(
          id: 'e2',
          description: 'Updated',
          amount: 500.0,
          category: ExpenseCategory.software,
          date: DateTime(2025, 6, 15),
          projectId: 'p2',
        );

        // Assert: All fields updated
        expect(modified.id, 'e2');
        expect(modified.description, 'Updated');
        expect(modified.amount, 500.0);
        expect(modified.category, ExpenseCategory.software);
        expect(modified.date.month, 6);
        expect(modified.projectId, 'p2');
      });
    });

    group('toJson - Integration', () {
      test('toJson_integration_serializesAndDeserializes', () {
        // Arrange: Original expense
        final original = Expense(
          id: 'e1',
          description: 'Integration Test Expense',
          amount: 7500.0,
          category: ExpenseCategory.equipment,
          date: DateTime(2025, 4, 20),
          projectId: 'p1',
        );

        // Act: Serialize to JSON, then deserialize back
        final json = original.toJson();
        final restored = Expense.fromJson(json);

        // Assert: All fields preserved
        expect(restored.id, original.id);
        expect(restored.description, original.description);
        expect(restored.amount, original.amount);
        expect(restored.category, original.category);
        expect(restored.projectId, original.projectId);
      });

      test('toJson_roundtripWithAllCategories', () {
        // Arrange: Test all categories survive roundtrip
        for (final category in ExpenseCategory.values) {
          final original = Expense(
            id: 'e1',
            description: 'Test',
            amount: 100.0,
            category: category,
            date: DateTime(2025, 1, 1),
            projectId: 'p1',
          );

          // Act
          final json = original.toJson();
          final restored = Expense.fromJson(json);

          // Assert: Category preserved
          expect(
            restored.category,
            category,
            reason: 'Category ${category.name} should survive roundtrip',
          );
        }
      });
    });

    group('imageUrl Field', () {
      test('fromMap_parsesImageUrl_correctly', () {
        final map = {
          'id': 'e1',
          'description': 'Test expense',
          'amount': 100.0,
          'category': 'materials',
          'date': '2025-01-01',
          'projectId': 'p1',
          'imageUrl': 'https://example.com/receipt.jpg',
        };

        final expense = Expense.fromMap(map);

        expect(expense.imageUrl, 'https://example.com/receipt.jpg');
      });

      test('fromMap_missingImageUrl_fallsBackToNull', () {
        final map = {
          'id': 'e1',
          'description': 'Test expense',
          'amount': 100.0,
          'category': 'materials',
          'date': '2025-01-01',
          'projectId': 'p1',
        };

        final expense = Expense.fromMap(map);

        expect(expense.imageUrl, isNull);
      });

      test('toMap_includesImageUrl_whenPresent', () {
        final expense = Expense(
          id: 'e1',
          description: 'Test',
          amount: 100.0,
          category: ExpenseCategory.materials,
          date: DateTime(2025, 1, 1),
          projectId: 'p1',
          imageUrl: 'https://example.com/receipt.jpg',
        );

        final map = expense.toMap();

        expect(map['imageUrl'], 'https://example.com/receipt.jpg');
      });

      test('toMap_excludesImageUrl_whenNull', () {
        final expense = Expense(
          id: 'e1',
          description: 'Test',
          amount: 100.0,
          category: ExpenseCategory.materials,
          date: DateTime(2025, 1, 1),
          projectId: 'p1',
        );

        final map = expense.toMap();

        expect(map['imageUrl'], isNull);
      });

      test('copyWith_updatesImageUrl', () {
        final original = Expense(
          id: 'e1',
          description: 'Test',
          amount: 100.0,
          category: ExpenseCategory.materials,
          date: DateTime(2025, 1, 1),
          projectId: 'p1',
        );

        final modified = original.copyWith(
          imageUrl: 'https://example.com/new.jpg',
        );

        expect(modified.imageUrl, 'https://example.com/new.jpg');
        expect(modified.id, original.id);
      });

      test('imageUrl_roundtrip_serializesAndDeserializes', () {
        final original = Expense(
          id: 'e1',
          description: 'Test',
          amount: 100.0,
          category: ExpenseCategory.materials,
          date: DateTime(2025, 1, 1),
          projectId: 'p1',
          imageUrl: 'https://example.com/receipt.jpg',
        );

        final json = original.toJson();
        final restored = Expense.fromJson(json);

        expect(restored.imageUrl, original.imageUrl);
      });
    });
  });
}
