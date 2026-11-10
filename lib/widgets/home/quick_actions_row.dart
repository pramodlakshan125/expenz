import 'package:expenz/constant/colors.dart';
import 'package:expenz/widgets/home/quick_action_item.dart';
import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;
  final VoidCallback? onBills;
  final VoidCallback? onSavings;

  const QuickActionsRow({
    super.key,
    this.onAddExpense,
    this.onAddIncome,
    this.onBills,
    this.onSavings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionItem(
              icon: Icons.remove_circle_outline_rounded,
              label: 'Add Expense',
              onTap: onAddExpense,
            ),
            QuickActionItem(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add Income',
              onTap: onAddIncome,
            ),
            QuickActionItem(
              icon: Icons.receipt_long_outlined,
              label: 'Bills',
              onTap: onBills,
            ),
            QuickActionItem(
              icon: Icons.savings_outlined,
              label: 'Savings',
              onTap: onSavings,
            ),
          ],
        ),
      ],
    );
  }
}
