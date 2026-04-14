import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/sqlite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_tile.dart';
import 'expense_submission_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Project? _project;
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    try {
      final projects = context.read<AppProvider>().projects;
      _project = projects.firstWhere(
        (p) => p.id == widget.projectId,
        orElse: () => throw Exception('Project not found'),
      );
      _expenses = await SqliteService.instance.getExpensesByProjectId(
        widget.projectId,
      );
    } catch (e) {
      print('Failed to load project: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _project?.name ?? 'Project',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExpenseSubmissionScreen(
                preSelectedProjectId: widget.projectId,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryCyan,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_project != null) ...[
                  _buildProjectInfo(),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (_expenses.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No expenses yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add your first expense',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
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
                final expense = _expenses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExpenseTile(expense: expense),
                );
              }, childCount: _expenses.length),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildProjectInfo() {
    final spent = _project?.spent ?? 0;
    final budget = _project?.budget ?? 0;
    final remaining = budget - spent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_project?.description != null) ...[
            Text(
              _project!.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn('Budget', '\$${budget.toStringAsFixed(0)}'),
              _buildStatColumn('Spent', '\$${spent.toStringAsFixed(0)}'),
              _buildStatColumn(
                'Remaining',
                '\$${remaining.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
