import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../theme/app_theme.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseTile({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          border: Border(
            bottom: BorderSide(color: AppTheme.textMuted.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              child: expense.imageUrl != null && expense.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        expense.imageUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildCategoryIcon(),
                      ),
                    )
                  : _buildCategoryIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        expense.category.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(expense.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '-\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (expense.category) {
      case ExpenseCategory.materials:
        return AppTheme.primaryBlue;
      case ExpenseCategory.travel:
        return AppTheme.accentPink;
      case ExpenseCategory.equipment:
        return AppTheme.warning;
      case ExpenseCategory.labor:
        return AppTheme.primaryCyan;
      case ExpenseCategory.software:
        return AppTheme.primaryGreen;
      case ExpenseCategory.marketing:
        return const Color(0xFF8B5CF6);
      case ExpenseCategory.utilities:
        return const Color(0xFF06B6D4);
      case ExpenseCategory.other:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildCategoryIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          expense.category.icon,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
