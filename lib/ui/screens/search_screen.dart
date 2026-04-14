import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_expense_tracker_user/ui/screens/project_details_screen.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';
import '../widgets/shimmer_loading.dart';
import '../../providers/app_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, AppProvider provider) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      provider.setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final results = provider.searchResults;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (query) => _onSearchChanged(query, provider),
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textMuted,
                      ),
                      suffixIcon: provider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                provider.clearFilters();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ExpenseCategory.values.map((category) {
                        final isSelected = provider.selectedCategories.contains(
                          category,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category.displayName),
                            selected: isSelected,
                            onSelected: (_) =>
                                provider.toggleCategoryFilter(category),
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.primaryCyan.withOpacity(
                              0.2,
                            ),
                            checkmarkColor: AppTheme.primaryCyan,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryCyan
                                  : AppTheme.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primaryCyan
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${results.length} results',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<SortOption>(
                          value: provider.sortOption,
                          underline: const SizedBox(),
                          isDense: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.textMuted,
                          ),
                          items: SortOption.values.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(
                                option.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (option) {
                            if (option != null) {
                              provider.setSortOption(option);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const ShimmerList()
                  : results.isEmpty
                  ? _buildEmptyState(provider)
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final project = results[index];
                        return ProjectCard(
                          project: project,
                          onTap: () => _navigateToProjectDetail(project),
                          onFavoriteToggle: () =>
                              provider.toggleFavorite(project.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppProvider provider) {
    final hasFilters =
        provider.searchQuery.isNotEmpty ||
        provider.selectedCategories.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.folder_open,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No projects match your search' : 'No projects yet',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                provider.clearFilters();
              },
              child: const Text(
                'Clear filters',
                style: TextStyle(
                  color: AppTheme.primaryCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToProjectDetail(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(projectId: project.id),
      ),
    );
  }
}

class _ProjectDetailScreenWrapper extends StatelessWidget {
  final Project project;

  const _ProjectDetailScreenWrapper({required this.project});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentProject = provider.projects.firstWhere(
      (p) => p.id == project.id,
      orElse: () => project,
    );

    return Hero(
      tag: 'project-${project.id}',
      child: Material(
        color: Colors.transparent,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.primaryCyan,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    currentProject.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHeaderStat('Budget', currentProject.budget),
                              _buildHeaderStat('Spent', currentProject.spent),
                              _buildHeaderStat(
                                'Remaining',
                                currentProject.remaining,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Description'),
                      const SizedBox(height: 8),
                      Text(
                        currentProject.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Progress'),
                      const SizedBox(height: 12),
                      _buildProgressBar(currentProject),
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Expenses (${currentProject.expenses.length})',
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final expense = currentProject.expenses[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            expense.category.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        expense.description ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${expense.category.displayName} - ${_formatDate(expense.date)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      trailing: Text(
                        '-\$${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  );
                }, childCount: currentProject.expenses.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${_formatAmount(amount)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildProgressBar(Project project) {
    final progressPercent = (project.progress * 100).toInt();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$progressPercent% used',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '\$${project.spent.toStringAsFixed(0)} of \$${project.budget.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: project.progress,
            backgroundColor: AppTheme.textMuted.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progressPercent > 80 ? AppTheme.warning : AppTheme.primaryCyan,
            ),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
