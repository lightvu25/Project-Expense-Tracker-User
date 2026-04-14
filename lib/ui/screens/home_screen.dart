import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/favorite_projects_chips.dart';
import '../widgets/project_card.dart';
import '../widgets/shimmer_loading.dart';
import '../../providers/app_provider.dart';
import 'project_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final projects = provider.projects;
    final favorites = provider.favoriteProjects;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.syncNow(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.isOnline ? 'Welcome back' : 'Offline Mode',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (!provider.isOnline)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.cloud_off,
                                size: 20,
                                color: AppTheme.warning,
                              ),
                            ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryCyan.withOpacity(
                              0.1,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: HeroCard(
                  totalBudget: provider.totalBudget,
                  totalSpent: provider.totalSpent,
                  totalRemaining: provider.totalRemaining,
                  activeProjects: provider.activeProjectCount,
                  totalProjects: provider.totalProjectCount,
                  completedProjects: provider.completedProjectCount,
                ),
              ),
              SliverToBoxAdapter(
                child: FavoriteProjectsChips(
                  favorites: favorites,
                  onProjectTap: _navigateToProjectDetail,
                  onRemoveFavorite: (project) =>
                      provider.toggleFavorite(project.id),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Projects',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: AppTheme.primaryCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: ShimmerList(itemCount: 3),
                  ),
                )
              else if (projects.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No projects available',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait for an admin to assign one.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final project = projects[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProjectCard(
                          project: project,
                          onTap: () => _navigateToProjectDetail(project),
                          onFavoriteToggle: () =>
                              provider.toggleFavorite(project.id),
                        ),
                      );
                    }, childCount: projects.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: provider.isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddProjectDialog(context),
              backgroundColor: AppTheme.primaryCyan,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _navigateToProjectDetail(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(projectId: project.id),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {}
}
