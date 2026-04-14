import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/sync_service.dart';
import '../services/sqlite_service.dart';

enum SortOption {
  nameAsc,
  nameDesc,
  dateNewest,
  dateOldest,
  budgetHigh,
  budgetLow,
  spentHigh,
  spentLow,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.nameAsc:
        return 'Name (A-Z)';
      case SortOption.nameDesc:
        return 'Name (Z-A)';
      case SortOption.dateNewest:
        return 'Date (Newest)';
      case SortOption.dateOldest:
        return 'Date (Oldest)';
      case SortOption.budgetHigh:
        return 'Budget (High)';
      case SortOption.budgetLow:
        return 'Budget (Low)';
      case SortOption.spentHigh:
        return 'Spent (High)';
      case SortOption.spentLow:
        return 'Spent (Low)';
    }
  }
}

class AppProvider extends ChangeNotifier {
  final SqliteService _sqliteService = SqliteService.instance;
  final SyncService _syncService = SyncService.instance;

  List<Project> _projects = [];
  Account? _currentAccount;
  bool _isLoading = false;
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _errorMessage;

  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateNewest;
  bool _isSearching = false;
  List<ExpenseCategory> _selectedCategories = [];

  List<Project> get projects => _projects;
  Account? get currentAccount => _currentAccount;
  bool get isLoading => _isLoading;
  SyncStatus get syncStatus => _syncStatus;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _syncService.isOnline;

  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  bool get isSearching => _isSearching;
  List<ExpenseCategory> get selectedCategories => _selectedCategories;

  List<Project> get favoriteProjects =>
      _projects.where((p) => p.isFavorite).toList();
  List<Project> get activeProjects =>
      _projects.where((p) => p.isActive).toList();
  List<Project> get completedProjects =>
      _projects.where((p) => !p.isActive).toList();

  bool get isAdmin => _currentAccount?.role == 'admin';

  int get totalProjectCount => _projects.length;
  int get activeProjectCount => activeProjects.length;
  int get completedProjectCount => completedProjects.length;

  List<Project> get searchResults {
    List<Project> filtered = List.from(_projects);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    if (_selectedCategories.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.expenses.any((e) => _selectedCategories.contains(e.category)),
          )
          .toList();
    }

    return sortProjects(filtered);
  }

  double get totalBudget => _projects.fold(0, (sum, p) => sum + p.budget);
  double get totalSpent => _projects.fold(0, (sum, p) => sum + p.spent);
  double get totalRemaining => totalBudget - totalSpent;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _syncService.initialize();

      // Listen to sync status changes
      _syncService.onSyncStatusChanged.listen((status) {
        _syncStatus = status;
        notifyListeners();

        // Reload projects when sync completes
        if (status == SyncStatus.synced || status == SyncStatus.idle) {
          loadProjects();
        }
      });

      // Load initial data from SQLite
      await loadProjects();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> loadProjects() async {
    _setLoading(true);
    try {
      _projects = await _sqliteService.getAllProjects();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load projects: ${e.toString()}';
    }
    _setLoading(false);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _isSearching = query.isNotEmpty || _selectedCategories.isNotEmpty;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleCategoryFilter(ExpenseCategory category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    _isSearching = _searchQuery.isNotEmpty || _selectedCategories.isNotEmpty;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategories.clear();
    _isSearching = false;
    notifyListeners();
  }

  List<Project> sortProjects(List<Project> projects) {
    final sorted = List<Project>.from(projects);
    switch (_sortOption) {
      case SortOption.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.dateNewest:
        sorted.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case SortOption.dateOldest:
        sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case SortOption.budgetHigh:
        sorted.sort((a, b) => b.budget.compareTo(a.budget));
        break;
      case SortOption.budgetLow:
        sorted.sort((a, b) => a.budget.compareTo(b.budget));
        break;
      case SortOption.spentHigh:
        sorted.sort((a, b) => b.spent.compareTo(a.spent));
        break;
      case SortOption.spentLow:
        sorted.sort((a, b) => a.spent.compareTo(b.spent));
        break;
    }
    return sorted;
  }

  Future<void> toggleFavorite(String projectId) async {
    try {
      await _syncService.toggleFavorite(projectId);
      await loadProjects();
    } catch (e) {
      _errorMessage = 'Failed to toggle favorite: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> syncNow() async {
    try {
      await _syncService.syncWithCloud();
      await loadProjects();
    } catch (e) {
      _errorMessage = 'Failed to sync: ${e.toString()}';
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setCurrentAccount(Account account) {
    _currentAccount = account;
    notifyListeners();
  }
}
