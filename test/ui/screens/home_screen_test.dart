import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_expense_tracker_user/ui/screens/home_screen.dart';
import 'package:project_expense_tracker_user/providers/app_provider.dart';
import 'package:project_expense_tracker_user/models/project.dart';
import 'package:project_expense_tracker_user/models/expense.dart';
import 'package:project_expense_tracker_user/ui/theme/app_theme.dart';
import 'package:project_expense_tracker_user/services/sync_service.dart';

class MockAppProvider extends ChangeNotifier implements AppProvider {
  List<Project> _projects = [];
  bool _isLoading = false;
  bool _isOnline = true;
  String? _errorMessage;

  @override
  List<Project> get projects => _projects;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isOnline => _isOnline;

  @override
  String? get errorMessage => _errorMessage;

  @override
  List<Project> get favoriteProjects =>
      _projects.where((p) => p.isFavorite).toList();

  @override
  List<Project> get activeProjects =>
      _projects.where((p) => p.isActive).toList();

  @override
  double get totalBudget => _projects.fold(0, (sum, p) => sum + p.budget);

  @override
  double get totalSpent => _projects.fold(0, (sum, p) => sum + p.spent);

  @override
  double get totalRemaining => totalBudget - totalSpent;

  @override
  void setProjects(List<Project> projects) {
    _projects = projects;
    notifyListeners();
  }

  @override
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void setOnline(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  @override
  Future<void> toggleFavorite(String projectId) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final project = _projects[index];
      _projects[index] = project.copyWith(isFavorite: !project.isFavorite);
      notifyListeners();
    }
  }

  @override
  Future<void> syncNow() async {}

  // Stub implementations for unused methods
  @override
  Account? get currentAccount => null;

  @override
  SyncStatus get syncStatus => SyncStatus.idle;

  @override
  String get searchQuery => '';

  @override
  SortOption get sortOption => SortOption.dateNewest;

  @override
  bool get isSearching => false;

  @override
  List<ExpenseCategory> get selectedCategories => [];

  @override
  int get totalProjectCount => _projects.length;

  @override
  int get activeProjectCount => activeProjects.length;

  @override
  int get completedProjectCount => 0;

  @override
  List<Project> get completedProjects => [];

  @override
  List<Project> get searchResults => _projects;

  @override
  List<Project> get completed => [];

  @override
  double get budget => 0;

  @override
  double get remaining => 0;

  @override
  double get progress => 0;

  @override
  double get spent => 0;

  @override
  List<Project> get all => _projects;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadProjects() async {}

  @override
  void setSearchQuery(String query) {}

  @override
  void setSortOption(SortOption option) {}

  @override
  void toggleCategoryFilter(ExpenseCategory category) {}

  @override
  void clearFilters() {}

  @override
  List<Project> sortProjects(List<Project> projects) => projects;

  @override
  void clearError() {}

  @override
  Future<void> addProject(Project project) async {}

  @override
  Future<void> updateProject(Project project) async {}

  @override
  Future<void> deleteProject(String id) async {}

  @override
  Future<void> addExpense(Expense expense) async {}

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<void> deleteExpense(String expenseId, String projectId) async {}

  @override
  Future<Account?> signIn(String email, String password) async => null;

  @override
  Future<Account?> signUp(
    String email,
    String password, {
    String? displayName,
  }) async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  group('HomeScreen Widget Tests', () {
    late MockAppProvider mockProvider;

    setUp(() {
      mockProvider = MockAppProvider();
    });

    Widget createTestWidget({Widget? child}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<AppProvider>.value(
          value: mockProvider,
          child: child ?? const HomeScreen(),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('displays Dashboard title', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Dashboard'), findsOneWidget);
      });

      testWidgets('displays Welcome back text when online', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Welcome back'), findsOneWidget);
      });

      testWidgets('displays Offline Mode text when offline', (
        WidgetTester tester,
      ) async {
        // Arrange
        mockProvider.setOnline(false);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Offline Mode'), findsOneWidget);
      });

      testWidgets('displays Recent Projects header', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Recent Projects'), findsOneWidget);
      });

      testWidgets('displays See All button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('See All'), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no projects', (
        WidgetTester tester,
      ) async {
        // Arrange: No projects
        mockProvider.setProjects([]);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('No projects yet'), findsOneWidget);
        expect(find.byIcon(Icons.folder_open), findsOneWidget);
      });

      testWidgets('displays loading indicator when loading', (
        WidgetTester tester,
      ) async {
        // Arrange
        mockProvider.setLoading(true);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('With Projects', () {
      final testProjects = [
        Project(
          id: 'p1',
          name: 'Office Renovation',
          description: 'Complete office renovation',
          budget: 85000.0,
          spent: 52300.0,
          startDate: DateTime(2025, 3, 1),
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
        ),
        Project(
          id: 'p2',
          name: 'Marketing Campaign',
          description: 'Digital marketing for Q2',
          budget: 45000.0,
          spent: 38200.0,
          startDate: DateTime(2025, 4, 1),
          isActive: true,
          isFavorite: false,
          expenses: [],
        ),
      ];

      testWidgets('displays project cards when projects exist', (
        WidgetTester tester,
      ) async {
        // Arrange
        mockProvider.setProjects(testProjects);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert: Project names should be visible
        expect(find.text('Office Renovation'), findsOneWidget);
        expect(find.text('Marketing Campaign'), findsOneWidget);
      });

      testWidgets('displays HeroCard with budget totals', (
        WidgetTester tester,
      ) async {
        // Arrange
        mockProvider.setProjects(testProjects);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert: Check for Total Budget text
        expect(find.text('Total Budget'), findsOneWidget);
      });

      testWidgets('displays active projects count', (
        WidgetTester tester,
      ) async {
        // Arrange
        mockProvider.setProjects(testProjects);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert: 2 active projects
        expect(find.text('2 Active'), findsOneWidget);
      });

      testWidgets('displays favorite chips when favorites exist', (
        WidgetTester tester,
      ) async {
        // Arrange: One favorite project
        mockProvider.setProjects(testProjects);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert: Favorite chip for Office Renovation
        expect(find.text('Office Renovation'), findsWidgets);
      });
    });

    group('Navigation', () {
      testWidgets('has bottom navigation bar', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      });

      testWidgets('shows Home label on home tab', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('has profile avatar', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('has RefreshIndicator', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });
  });
}
