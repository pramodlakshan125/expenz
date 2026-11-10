import 'package:expenz/constant/colors.dart';
import 'package:expenz/constant/app_icons.dart';
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
              icon: AppIcons.plus,
              label: 'Add Expense',
              onTap: onAddExpense,
            ),
            QuickActionItem(
              icon: AppIcons.income,
              label: 'Add Income',
              onTap: onAddIncome,
            ),
            QuickActionItem(
              icon: AppIcons.bills,
              color: const Color(0xFF3C4C52),
              label: 'Bills',
              onTap: onBills,
            ),
            QuickActionItem(
              icon: AppIcons.money,
              label: 'Savings',
              onTap: onSavings,
            ),
          ],
        ),
      ],
    );
  }
}
