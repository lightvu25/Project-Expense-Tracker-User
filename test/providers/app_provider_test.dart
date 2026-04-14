import 'package:flutter_test/flutter_test.dart';
import 'package:project_expense_tracker_user/providers/app_provider.dart';
import 'package:project_expense_tracker_user/models/project.dart';
import 'package:project_expense_tracker_user/models/expense.dart';

void main() {
  group('AppProvider - Sorting & Filtering Logic', () {
    late AppProvider provider;

    setUp(() {
      provider = AppProvider();
    });

    group('sortProjects', () {
      final testProjects = [
        Project(
          id: 'p1',
          name: 'Beta Project',
          description: 'Second alphabetically',
          budget: 10000.0,
          spent: 5000.0,
          startDate: DateTime(2025, 3, 1),
          isActive: true,
          expenses: [],
        ),
        Project(
          id: 'p2',
          name: 'Alpha Project',
          description: 'First alphabetically',
          budget: 20000.0,
          spent: 10000.0,
          startDate: DateTime(2025, 1, 15),
          isActive: true,
          expenses: [],
        ),
        Project(
          id: 'p3',
          name: 'Gamma Project',
          description: 'Third alphabetically',
          budget: 5000.0,
          spent: 1000.0,
          startDate: DateTime(2025, 6, 1),
          isActive: true,
          expenses: [],
        ),
      ];

      test('sortProjects_nameAsc sorts alphabetically A-Z', () {
        // Arrange
        provider.setSortOption(SortOption.nameAsc);

        // Act
        final sorted = provider.sortProjects(testProjects);

        // Assert
        expect(sorted[0].name, 'Alpha Project');
        expect(sorted[1].name, 'Beta Project');
        expect(sorted[2].name, 'Gamma Project');
      });

      test('sortProjects_nameDesc sorts alphabetically Z-A', () {
        // Arrange
        provider.setSortOption(SortOption.nameDesc);

        // Act
        final sorted = provider.sortProjects(testProjects);

        // Assert
        expect(sorted[0].name, 'Gamma Project');
        expect(sorted[1].name, 'Beta Project');
        expect(sorted[2].name, 'Alpha Project');
      });

      test('sortProjects_dateNewest sorts by date descending', () {
        // Arrange
        provider.setSortOption(SortOption.dateNewest);

        // Act
        final sorted = provider.sortProjects(testProjects);

        // Assert
        expect(sorted[0].name, 'Gamma Project');
        expect(sorted[1].name, 'Beta Project');
        expect(sorted[2].name, 'Alpha Project');
      });

      test('sortProjects_dateOldest sorts by date ascending', () {
        // Arrange
        provider.setSortOption(SortOption.dateOldest);

        // Act
        final sorted = provider.sortProjects(testProjects);

        // Assert
        expect(sorted[0].name, 'Alpha Project');
        expect(sorted[1].name, 'Beta Project');
        expect(sorted[2].name, 'Gamma Project');
      });

      test('sortProjects_budgetHigh sorts by budget descending', () {
        // Arrange
        provider.setSortOption(SortOption.budgetHigh);

        // Act
        final sorted = provider.sortProjects(testProjects);

        // Assert
        expect(sorted[0].budget, 20000.0);
        expect(sorted[1].budget, 10000.0);
        expect(sorted[2].budget, 5000.0);
      });

      test('sortProjects_budgetLow sorts by budget ascending', () {
        // Arrange
        provider.setSortOption(SortOption.budgetLow);

        // Act
        final sorted = provider.sortProjects(testProjects);

        // Assert
        expect(sorted[0].budget, 5000.0);
        expect(sorted[1].budget, 10000.0);
        expect(sorted[2].budget, 20000.0);
      });

      test('sortProjects_spentHigh sorts by spent descending', () {
        // Arrange
        provider.setSortOption(SortOption.spentHigh);

        // Act
        final sorted = provider.sortProjects(testProjects);

        // Assert
        expect(sorted[0].spent, 10000.0);
        expect(sorted[1].spent, 5000.0);
        expect(sorted[2].spent, 1000.0);
      });

      test('sortProjects_spentLow sorts by spent ascending', () {
        // Arrange
        provider.setSortOption(SortOption.spentLow);

        // Act
        final sorted = provider.sortProjects(testProjects);

        // Assert
        expect(sorted[0].spent, 1000.0);
        expect(sorted[1].spent, 5000.0);
        expect(sorted[2].spent, 10000.0);
      });
    });

    group('Search & Filter Logic', () {
      final projectsWithExpenses = [
        Project(
          id: 'p1',
          name: 'Office Renovation',
          description: 'Complete office renovation project',
          budget: 85000.0,
          spent: 52300.0,
          startDate: DateTime(2025, 3, 1),
          isActive: true,
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
        ),
        Project(
          id: 'p2',
          name: 'Marketing Campaign',
          description: 'Digital marketing for Q2',
          budget: 45000.0,
          spent: 38200.0,
          startDate: DateTime(2025, 4, 1),
          isActive: true,
          expenses: [
            Expense(
              id: 'e2',
              description: 'Facebook Ads',
              amount: 12000.0,
              category: ExpenseCategory.services,
              date: DateTime(2025, 4, 5),
              projectId: 'p2',
            ),
          ],
        ),
        Project(
          id: 'p3',
          name: 'Tech Upgrade',
          description: 'Server and equipment upgrade',
          budget: 120000.0,
          spent: 98500.0,
          startDate: DateTime(2025, 2, 1),
          isActive: true,
          expenses: [
            Expense(
              id: 'e3',
              description: 'New servers',
              amount: 45000.0,
              category: ExpenseCategory.equipment,
              date: DateTime(2025, 2, 15),
              projectId: 'p3',
            ),
          ],
        ),
      ];

      test('searchResults_searchByName_findsMatchingProjects', () {
        // Arrange: Set a search query
        provider.setSearchQuery('marketing');

        // Act: Get search results
        final results = provider.searchResults;

        // Assert: Finds projects matching the query
        expect(results.length, 1);
        expect(results.first.name, 'Marketing Campaign');
      });

      test('searchResults_searchByDescription_findsMatchingProjects', () {
        // Arrange
        provider.setSearchQuery('digital');

        // Act
        final results = provider.searchResults;

        // Assert
        expect(results.length, 1);
        expect(results.first.description, contains('Digital'));
      });

      test('searchResults_searchCaseInsensitive', () {
        // Arrange
        provider.setSearchQuery('OFFICE');

        // Act
        final results = provider.searchResults;

        // Assert: Case insensitive search works
        expect(results.length, 1);
        expect(results.first.name, 'Office Renovation');
      });

      test('searchResults_noMatch_returnsEmpty', () {
        // Arrange
        provider.setSearchQuery('nonexistent project xyz');

        // Act
        final results = provider.searchResults;

        // Assert
        expect(results, isEmpty);
      });

      test('searchResults_emptyQuery_returnsAllProjects', () {
        // Arrange: Empty search query
        provider.setSearchQuery('');

        // Act
        final results = provider.searchResults;

        // Assert: Returns all projects (sorted by default)
        expect(results.length, 3);
      });

      test('searchResults_filterByCategory_filtersExpenses', () {
        // Arrange: Filter by materials category
        provider.toggleCategoryFilter(ExpenseCategory.materials);

        // Act
        final results = provider.searchResults;

        // Assert: Returns projects with materials expenses
        expect(results.length, 1);
        expect(results.first.name, 'Office Renovation');
      });

      test('searchResults_multipleCategories_filtersCorrectly', () {
        // Arrange: Filter by multiple categories
        provider.toggleCategoryFilter(ExpenseCategory.equipment);
        provider.toggleCategoryFilter(ExpenseCategory.services);

        // Act
        final results = provider.searchResults;

        // Assert: Returns projects with equipment OR marketing expenses
        expect(results.length, 2);
        expect(results.any((p) => p.name == 'Marketing Campaign'), true);
        expect(results.any((p) => p.name == 'Tech Upgrade'), true);
      });

      test('searchResults_categoryAndSearch_combinesFilters', () {
        // Arrange: Search query + category filter
        provider.setSearchQuery('campaign');
        provider.toggleCategoryFilter(ExpenseCategory.services);

        // Act
        final results = provider.searchResults;

        // Assert: Both filters apply
        expect(results.length, 1);
        expect(results.first.name, 'Marketing Campaign');
      });

      test('clearFilters_resetsAllFilters', () {
        // Arrange: Set some filters
        provider.setSearchQuery('test');
        provider.toggleCategoryFilter(ExpenseCategory.materials);

        // Act: Clear all filters
        provider.clearFilters();

        // Assert: Filters are reset
        expect(provider.searchQuery, '');
        expect(provider.selectedCategories, isEmpty);
        expect(provider.isSearching, false);
      });
    });

    group('SortOption Extension', () {
      test('displayName_nameAsc returns correct string', () {
        expect(SortOption.nameAsc.displayName, 'Name (A-Z)');
      });

      test('displayName_nameDesc returns correct string', () {
        expect(SortOption.nameDesc.displayName, 'Name (Z-A)');
      });

      test('displayName_dateNewest returns correct string', () {
        expect(SortOption.dateNewest.displayName, 'Date (Newest)');
      });

      test('displayName_dateOldest returns correct string', () {
        expect(SortOption.dateOldest.displayName, 'Date (Oldest)');
      });

      test('displayName_budgetHigh returns correct string', () {
        expect(SortOption.budgetHigh.displayName, 'Budget (High)');
      });

      test('displayName_budgetLow returns correct string', () {
        expect(SortOption.budgetLow.displayName, 'Budget (Low)');
      });

      test('displayName_spentHigh returns correct string', () {
        expect(SortOption.spentHigh.displayName, 'Spent (High)');
      });

      test('displayName_spentLow returns correct string', () {
        expect(SortOption.spentLow.displayName, 'Spent (Low)');
      });
    });

    group('Provider State Management', () {
      test('setSortOption_updatesSortOption', () {
        // Arrange & Act
        provider.setSortOption(SortOption.budgetHigh);

        // Assert
        expect(provider.sortOption, SortOption.budgetHigh);
      });

      test('toggleCategoryFilter_addsCategory', () {
        // Arrange & Act
        provider.toggleCategoryFilter(ExpenseCategory.materials);

        // Assert
        expect(
          provider.selectedCategories.contains(ExpenseCategory.materials),
          true,
        );
      });

      test('toggleCategoryFilter_removesCategoryWhenAlreadySelected', () {
        // Arrange: Add category first
        provider.toggleCategoryFilter(ExpenseCategory.materials);
        expect(
          provider.selectedCategories.contains(ExpenseCategory.materials),
          true,
        );

        // Act: Toggle again to remove
        provider.toggleCategoryFilter(ExpenseCategory.materials);

        // Assert
        expect(
          provider.selectedCategories.contains(ExpenseCategory.materials),
          false,
        );
      });

      test('isSearching_trueWhenSearchQueryPresent', () {
        // Arrange
        provider.setSearchQuery('test');

        // Assert
        expect(provider.isSearching, true);
      });

      test('isSearching_trueWhenCategoriesSelected', () {
        // Arrange
        provider.toggleCategoryFilter(ExpenseCategory.materials);

        // Assert
        expect(provider.isSearching, true);
      });

      test('isSearching_falseWhenNoFilters', () {
        // Arrange
        provider.clearFilters();

        // Assert
        expect(provider.isSearching, false);
      });
    });
  });
}
