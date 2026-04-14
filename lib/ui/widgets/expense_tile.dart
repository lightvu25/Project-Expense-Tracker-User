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
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(),
              const SizedBox(height: 12),
              _buildDescriptionRow(),
              const SizedBox(height: 12),
              _buildMiddleRow(),
              const SizedBox(height: 12),
              _buildBottomRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    final title = (expense.title?.isNotEmpty ?? false)
        ? expense.title!
        : 'Untitled Expense';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionRow() {
    if (expense.description == null || expense.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        expense.description!,
        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMiddleRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [_buildCategoryChip(), _buildStatusChip()],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        expense.category.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getCategoryColor(),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final statusColor = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        expense.paymentStatus,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(expense.date),
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        Row(
          children: [
            Icon(_getPaymentMethodIcon(), size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              expense.paymentMethod,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
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
      case ExpenseCategory.services:
        return AppTheme.warning;
      case ExpenseCategory.utilities:
        return const Color(0xFF06B6D4);
      case ExpenseCategory.miscellaneous:
        return AppTheme.textSecondary;
    }
  }

  Color _getStatusColor() {
    switch (expense.paymentStatus) {
      case 'Pending':
        return AppTheme.warning;
      case 'Paid':
        return AppTheme.primaryGreen;
      case 'Reimbursed':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.warning;
    }
  }

  IconData _getPaymentMethodIcon() {
    switch (expense.paymentMethod.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'credit card':
        return Icons.credit_card;
      case 'bank transfer':
        return Icons.account_balance;
      case 'cheque':
        return Icons.receipt;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
