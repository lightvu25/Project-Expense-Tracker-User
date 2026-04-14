import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_favorite_button.dart';
import '../widgets/shimmer_loading.dart';
import '../../providers/app_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final favorites = provider.favoriteProjects;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${favorites.length} projects',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const ShimmerGrid(itemCount: 6)
                  : favorites.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final project = favorites[index];
                        return _FavoriteCard(
                          project: project,
                          onTap: () =>
                              _navigateToProjectDetail(context, project),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon on any project\nto add it to your favorites',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  void _navigateToProjectDetail(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ProjectDetailScreenWrapper(project: project),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _FavoriteCard({
    required this.project,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: project.isActive
                              ? AppTheme.success.withOpacity(0.1)
                              : AppTheme.textMuted.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project.isActive ? 'Active' : 'Completed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: project.isActive
                                ? AppTheme.success
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                      AnimatedFavoriteButton(
                        isFavorite: project.isFavorite,
                        onToggle: onFavoriteToggle,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '\$${_formatAmount(project.budget)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progress,
                      backgroundColor: AppTheme.textMuted.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (project.progress * 100) > 80
                            ? AppTheme.warning
                            : AppTheme.primaryCyan,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
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
